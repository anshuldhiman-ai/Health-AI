import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

/// On-device food recognition (Section 8.7, ADR 0004).
///
/// One MobileNetV4 student, exported to LiteRT with ImageNet
/// normalisation baked into the graph. The fallback path is *inside*
/// this single model pipeline:
///
/// 1. Run the photo.
/// 2. If the top-1 probability or the top-1/top-2 margin is low, run a
///    horizontal-flip test-time augmentation and average the two
///    distributions (a real error-reduction step, no second model).
/// 3. If it is still ambiguous, mark the result uncertain. The UI then
///    shows the top-3 dishes with their key ingredients so the user
///    resolves the ambiguity — a wrong guess is never silently logged.
///
/// Calories are always computed as a range from per-100 g macros and
/// the chosen serving; macros come from the same catalog.
class DishScore {
  const DishScore({required this.label, required this.confidence});

  final String label;

  /// 0..1 probability after softmax (temperature 1.0).
  final double confidence;

  int get percent => (confidence * 100).round();
}

class RecognitionOutput {
  const RecognitionOutput({
    required this.top,
    required this.uncertain,
    required this.ratio,
    required this.usedTta,
    required this.latencyMs,
    this.isFood = true,
  });

  final List<DishScore> top;

  /// True when the model is not confident enough to log without the
  /// user confirming the dish/ingredients.
  final bool uncertain;

  /// How many times more likely the top class is than the runner-up.
  /// 1.0 means the top two are tied. This is comparable across
  /// models with different class counts, unlike the raw probability.
  final double ratio;

  /// Whether the flip-TTA fallback ran.
  final bool usedTta;

  final int latencyMs;

  /// False when the photo doesn't contain a recognizable food dish.
  final bool isFood;
}

/// Asset paths for the exported model + label order.
const kFoodModelAsset = 'assets/models/baseline.tflite';
const kFoodLabelsAsset = 'assets/models/labels.json';

/// Decision thresholds.
///
/// The absolute probability of the top class is NOT comparable across
/// models: a softmax over 80 classes concentrates far more mass than
/// the same quality of model over 239. The old model (80 classes) put
/// ~0.6 on its top guess for a photo of anything; the new model (239
/// classes) spreads the same evidence thinner, so the same absolute
/// threshold would call every correct answer "uncertain" and, worse,
/// the old threshold would have called the old model's confident
/// garbage "certain".
///
/// So the decision uses the MARGIN between the top two classes,
/// normalised by how much probability mass is available beyond the
/// runner-up. A margin of 0 is "two classes tied" regardless of the
/// class count; the ratio top1/top2 says the same thing more
/// sharply, and unlike an absolute probability it does not move when
/// the class set changes.
///
/// The absolute top-1 probability is still checked, but against a
/// floor low enough to be meaningful for a many-class model, and the
/// ratio carries the real weight.
const _kTtaRatio = 1.6;
const _kUncertainRatio = 1.35;
const _kUncertainTop1Floor = 0.12;

/// Food / not-food thresholds, used by [TopConfidence.isLikelyFood].
///
/// PROVISIONAL. The bundled label set is 239 Indian dishes and holds no
/// `not_food` / `other_food` class, so there is nothing to train or
/// calibrate this decision against - it is a heuristic on the shape of
/// the probability distribution, not a learned reject class.
///
/// Validating these numbers needs a labelled set of real non-food phone
/// photos (keyboards, pets, walls, furniture) pushed through this exact
/// model, which does not exist yet. Until it does, treat every constant
/// here as an unmeasured guess. The unit tests cover the decision LOGIC;
/// they cannot tell you these cut-offs are right.
///
/// Erring strict is deliberate: a false "not a food item" costs the user
/// one tap on Search manually, while a false "food" writes a confident
/// wrong dish into their diary (R4).
const _kFoodTop1Floor = 0.15;
const _kFoodTop3MassFloor = 0.48;

/// A margin this wide is food evidence on its own: the model separated
/// one distinctive dish from everything else. It rescues a picture whose
/// mass sits mostly on the top class, which [_kFoodTop3MassFloor] alone
/// would reject.
const _kFoodClearMarginRatio = 2.4;

const _kImageSize = 224;
const _kResizeShortSide = 255;

class ModelUnavailableException implements Exception {
  const ModelUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RecognitionException implements Exception {
  const RecognitionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// How confident the model is, in terms that do not change when the
/// class count does.
class TopConfidence {
  const TopConfidence({
    required this.top1,
    required this.top2,
    required this.ratio,
    required this.top3Mass,
  });

  /// Summarise a full probability distribution.
  ///
  /// Kept as a factory rather than a private method on the recogniser so
  /// the decision can be unit-tested without a LiteRT interpreter.
  factory TopConfidence.fromProbabilities(List<double> probs) {
    var first = 0.0, second = 0.0, third = 0.0;
    for (final p in probs) {
      if (p > first) {
        third = second;
        second = first;
        first = p;
      } else if (p > second) {
        third = second;
        second = p;
      } else if (p > third) {
        third = p;
      }
    }
    // A near-zero runner-up means a ratio of infinity; clamp it so the
    // value stays finite and comparable.
    final ratio = second <= 0 ? 1e9 : first / second;
    return TopConfidence(
      top1: first,
      top2: second,
      ratio: ratio,
      top3Mass: first + second + third,
    );
  }

  /// Probability of the top class.
  final double top1;

  /// Probability of the runner-up.
  final double top2;

  /// top1 / top2. 1.0 means "the top two are tied"; a large value
  /// means the model is sure.
  final double ratio;

  /// Combined probability of the three best classes.
  ///
  /// The distribution signal: a real dish photo concentrates its mass on
  /// a few plausible dishes, whereas a keyboard or a wall spreads the
  /// same total thinly across 239 unrelated classes, so the top three
  /// hold much less of it.
  final double top3Mass;

  /// True when the result should be presented as a guess rather than
  /// an answer.
  ///
  /// Two independent reasons to doubt it: the top class does not
  /// clearly beat the runner-up, or it does not carry enough
  /// probability mass on its own.
  bool get isUncertain =>
      ratio < _kUncertainRatio || top1 < _kUncertainTop1Floor;

  /// True when the photo plausibly contains a dish at all.
  ///
  /// This asks only "is there food here?", never "which dish?" — that is
  /// [isUncertain]'s job. The two questions need different evidence, and
  /// conflating them produces a bad answer for real food:
  ///
  /// - [top1]: *some* class must carry real mass. A softmax over 239
  ///   classes always returns a biggest number, so "there is a maximum"
  ///   means nothing on its own.
  /// - [top3Mass] or [ratio]: the mass must sit on a few dishes rather
  ///   than be smeared over the whole class list, either because the top
  ///   three hold it ([top3Mass]) or because the winner is far ahead of
  ///   everything else ([ratio]).
  ///
  /// A LOW [ratio] is deliberately NOT treated as evidence of non-food.
  /// "Dal tadka vs dal makhani" produces a near-tie between two dishes,
  /// which is strong evidence the picture IS food and merely ambiguous
  /// between two labels — [isUncertain] flags it, the user picks. Using
  /// the margin as a food gate would answer a photo of a real dish with
  /// "Not a food item", which is worse than a guess the user can correct.
  ///
  /// See the threshold constants for why these numbers are provisional.
  bool get isLikelyFood =>
      top1 >= _kFoodTop1Floor &&
      (top3Mass >= _kFoodTop3MassFloor || ratio >= _kFoodClearMarginRatio);
}

/// Decode, orient, resize + centre-crop, then lay out RGB floats in
/// NHWC (the exported graph's input layout). Runs in an isolate.
Float32List preprocessFoodPhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const RecognitionException('Could not read that photo.');
  }
  final oriented = img.bakeOrientation(decoded);

  // Eval transform: resize the shorter side to 255, centre-crop 224.
  final short = math.min(oriented.width, oriented.height);
  if (short <= 0) {
    throw const RecognitionException('Could not read that photo.');
  }
  final scale = _kResizeShortSide / short;
  final resized = img.copyResize(
    oriented,
    width: math.max(_kImageSize, (oriented.width * scale).round()),
    height: math.max(_kImageSize, (oriented.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );

  // torchvision's CenterCrop rounds the offset; match it so the
  // on-device input is the same crop the model was validated with.
  final x0 = ((resized.width - _kImageSize) / 2).round();
  final y0 = ((resized.height - _kImageSize) / 2).round();
  final crop = img.copyCrop(
    resized,
    x: x0,
    y: y0,
    width: _kImageSize,
    height: _kImageSize,
  );

  final out = Float32List(_kImageSize * _kImageSize * 3);
  var i = 0;
  for (var y = 0; y < _kImageSize; y++) {
    for (var x = 0; x < _kImageSize; x++) {
      final p = crop.getPixel(x, y);
      out[i++] = p.r / 255.0;
      out[i++] = p.g / 255.0;
      out[i++] = p.b / 255.0;
    }
  }
  return out;
}

Float32List flipHorizontally(Float32List nhwc) {
  final out = Float32List(nhwc.length);
  for (var y = 0; y < _kImageSize; y++) {
    final row = y * _kImageSize;
    for (var x = 0; x < _kImageSize; x++) {
      final src = (row + x) * 3;
      final dst = (row + (_kImageSize - 1 - x)) * 3;
      out[dst] = nhwc[src];
      out[dst + 1] = nhwc[src + 1];
      out[dst + 2] = nhwc[src + 2];
    }
  }
  return out;
}

class FoodRecognizer {
  FoodRecognizer();

  _LoadedModel? _model;
  Future<_LoadedModel>? _loading;
  Future<void> _queue = Future.value();

  /// Lazily loads the model asset. Throws [ModelUnavailableException]
  /// when the app was built without the exported model (assets are not
  /// committed; see R8).
  Future<_LoadedModel> _load() {
    final ready = _model;
    if (ready != null) return Future.value(ready);

    return _loading ??= _create()
        .then((loaded) {
          _model = loaded;
          return loaded;
        })
        .catchError((Object error) {
          _loading = null;
          if (error is ModelUnavailableException) throw error;
          throw ModelUnavailableException('Model could not be loaded: $error');
        });
  }

  Future<_LoadedModel> _create() async {
    late final List<String> labels;
    try {
      final raw = await rootBundle.loadString(kFoodLabelsAsset);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      labels = (decoded['classes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(growable: false);
    } catch (error) {
      throw ModelUnavailableException(
        'Missing $kFoodLabelsAsset. Run the ML export first ($error).',
      );
    }

    late final Interpreter interpreter;
    final options = InterpreterOptions()..threads = 4;
    try {
      interpreter = await Interpreter.fromAsset(
        kFoodModelAsset,
        options: options,
      );
    } catch (error) {
      throw ModelUnavailableException(
        'Missing $kFoodModelAsset. Run the ML export first ($error).',
      );
    } finally {
      options.delete();
    }

    // The output buffer is sized from the label count, so a model whose
    // output dimension does not match labels.json would write past
    // the buffer and produce garbage logits (a confident, wrong dish).
    // Check the shapes at load time instead.
    final outputSize = _verifyModelShapes(interpreter, labels.length);

    final isolate = await IsolateInterpreter.create(
      address: interpreter.address,
      debugName: 'food-recognizer',
    );
    return _LoadedModel(
      interpreter: interpreter,
      isolate: isolate,
      labels: labels,
      outputSize: outputSize,
    );
  }

  /// Fail loudly if the model's input/output shapes do not match the
  /// app's contract. Returns the model's output size.
  static int _verifyModelShapes(Interpreter interpreter, int numLabels) {
    final inputs = interpreter.getInputTensors();
    if (inputs.isEmpty) {
      throw const ModelUnavailableException('The model has no input tensor.');
    }
    final inputShape = inputs.first.shape;
    const expectedInput = [1, 224, 224, 3];
    if (inputShape.length != expectedInput.length ||
        !_sameShape(inputShape, expectedInput)) {
      throw ModelUnavailableException(
        'The model expects input $inputShape but the app provides '
        '$expectedInput. Re-export the model.',
      );
    }

    final outputs = interpreter.getOutputTensors();
    if (outputs.isEmpty) {
      throw const ModelUnavailableException('The model has no output tensor.');
    }
    final outputShape = outputs.first.shape;
    if (outputShape.isEmpty || outputShape.last != numLabels) {
      throw ModelUnavailableException(
        'The model outputs ${outputShape.isEmpty ? 0 : outputShape.last} '
        'classes but labels.json lists $numLabels. The model and the '
        'labels are out of sync - re-export the model.',
      );
    }
    return outputShape.last;
  }

  static bool _sameShape(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Run recognition. Serialised so two quick captures cannot mutate
  /// the shared interpreter at once.
  Future<RecognitionOutput> recognize(Uint8List photo) {
    final result = _queue.then((_) => _recognize(photo));
    _queue = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<RecognitionOutput> _recognize(Uint8List photo) async {
    final model = await _load();
    final started = DateTime.now();

    final Float32List input;
    try {
      input = await Isolate.run(() => preprocessFoodPhoto(photo));
    } on RecognitionException {
      rethrow;
    } catch (error) {
      throw RecognitionException('Could not read that photo ($error).');
    }

    var probs = _softmax(await _run(model, input));
    var confidence = TopConfidence.fromProbabilities(probs);
    var usedTta = false;

    // The flip-TTA runs when the top two classes are close: that is
    // exactly the case where the model is unsure and a second look
    // helps. The ratio is the trigger, so it works the same for 80
    // classes and 239.
    if (confidence.ratio < _kTtaRatio) {
      final flipped = flipHorizontally(input);
      final flipProbs = _softmax(await _run(model, flipped));
      probs = List<double>.generate(
        probs.length,
        (i) => (probs[i] + flipProbs[i]) / 2,
      );
      confidence = TopConfidence.fromProbabilities(probs);
      usedTta = true;
    }

    final ranked = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    final top = [
      for (final index in ranked.take(3))
        if (index < model.labels.length)
          DishScore(label: model.labels[index], confidence: probs[index]),
    ];

    // Non-food rejection. Computed AFTER the TTA block above, so it
    // judges the averaged distribution rather than the first pass.
    final isFood = confidence.isLikelyFood;

    return RecognitionOutput(
      top: top,
      uncertain: confidence.isUncertain,
      ratio: confidence.ratio,
      usedTta: usedTta,
      latencyMs: DateTime.now().difference(started).inMilliseconds,
      isFood: isFood,
    );
  }

  Future<List<double>> _run(_LoadedModel model, Float32List input) async {
    // ByteBuffer avoids the runtime shape-resize path; the graph is
    // fixed at 1x224x224x3.
    //
    // The buffer is sized from the MODEL's output tensor, not from the
    // label count: if the two ever disagree, sizing from the label
    // count would make the interpreter write past the end of the
    // buffer and fill it with garbage.
    final outBytes = ByteData(model.outputSize * 4);
    await model.isolate
        .run(input.buffer, outBytes.buffer)
        .timeout(const Duration(seconds: 30));
    return outBytes.buffer.asFloat32List().toList(growable: false);
  }


  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) {
      throw const RecognitionException('Model returned no scores.');
    }
    final maxLogit = logits.reduce(math.max);
    var sum = 0.0;
    final exps = List<double>.filled(logits.length, 0);
    for (var i = 0; i < logits.length; i++) {
      final e = math.exp(logits[i] - maxLogit);
      exps[i] = e;
      sum += e;
    }
    if (sum == 0) {
      throw const RecognitionException('Model returned invalid scores.');
    }
    for (var i = 0; i < exps.length; i++) {
      exps[i] /= sum;
    }
    return exps;
  }

  Future<void> dispose() async {
    final model = _model;
    _model = null;
    _loading = null;
    if (model != null) {
      await model.isolate.close();
      if (!model.interpreter.isDeleted) model.interpreter.close();
    }
  }
}

class _LoadedModel {
  const _LoadedModel({
    required this.interpreter,
    required this.isolate,
    required this.labels,
    required this.outputSize,
  });

  final Interpreter interpreter;
  final IsolateInterpreter isolate;
  final List<String> labels;

  /// Number of floats the model writes. Taken from the model's own
  /// output tensor, never from the label count.
  final int outputSize;
}

/// App-wide recogniser: the model stays warm across scans. The UI never
/// talks to LiteRT directly.
final foodRecognizerProvider = Provider<FoodRecognizer>((ref) {
  final recognizer = FoodRecognizer();
  ref.onDispose(recognizer.dispose);
  return recognizer;
});
