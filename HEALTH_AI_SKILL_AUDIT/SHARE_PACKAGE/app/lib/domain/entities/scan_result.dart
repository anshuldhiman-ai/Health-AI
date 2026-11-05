import 'package:app/domain/entities/dish_record.dart';
import 'package:app/domain/entities/plate_geometry.dart';

/// Top-K dish classification score with calibrated probability (AGENTS.md §5.3, §6.4).
class DishScore {
  const DishScore({required this.dishId, required this.calibratedProb});

  final String dishId;
  final double calibratedProb;

  @override
  String toString() => '$dishId: ${(calibratedProb * 100).toStringAsFixed(1)}%';
}

/// A detected food item segmented from the plate (AGENTS.md §5.3).
class DetectedItem {
  const DetectedItem({
    required this.regionId,
    required this.role,
    required this.outline,
    required this.areaCm2,
    this.containerId,
    required this.topK,
    required this.dishId,
    this.isGenericFallback = false,
    this.pieceCount,
    required this.grams,
    required this.kcal,
    required this.macros,
    this.flags = const {},
  });

  final String regionId;
  final Role role;
  final List<Point2D> outline;
  final double areaCm2;
  final String? containerId;
  final List<DishScore> topK;
  final String dishId;
  final bool isGenericFallback;
  final int? pieceCount;
  final Range grams;
  final Range kcal;
  final Macros macros;
  final Set<ConfidenceFlag> flags;

  DetectedItem copyWith({
    String? regionId,
    Role? role,
    List<Point2D>? outline,
    double? areaCm2,
    String? containerId,
    List<DishScore>? topK,
    String? dishId,
    bool? isGenericFallback,
    int? pieceCount,
    Range? grams,
    Range? kcal,
    Macros? macros,
    Set<ConfidenceFlag>? flags,
  }) {
    return DetectedItem(
      regionId: regionId ?? this.regionId,
      role: role ?? this.role,
      outline: outline ?? this.outline,
      areaCm2: areaCm2 ?? this.areaCm2,
      containerId: containerId ?? this.containerId,
      topK: topK ?? this.topK,
      dishId: dishId ?? this.dishId,
      isGenericFallback: isGenericFallback ?? this.isGenericFallback,
      pieceCount: pieceCount ?? this.pieceCount,
      grams: grams ?? this.grams,
      kcal: kcal ?? this.kcal,
      macros: macros ?? this.macros,
      flags: flags ?? this.flags,
    );
  }
}

/// Breakdown of latency across pipeline stages in milliseconds.
class StageTimings {
  const StageTimings({
    this.preprocessMs = 0.0,
    this.segmenterMs = 0.0,
    this.postprocessMs = 0.0,
    this.embedderMs = 0.0,
    this.mathMs = 0.0,
    this.totalMs = 0.0,
  });

  final double preprocessMs;
  final double segmenterMs;
  final double postprocessMs;
  final double embedderMs;
  final double mathMs;
  final double totalMs;

  @override
  String toString() =>
      'StageTimings(total: ${totalMs.toStringAsFixed(1)}ms, seg: ${segmenterMs.toStringAsFixed(1)}ms, emb: ${embedderMs.toStringAsFixed(1)}ms)';
}

/// Complete multi-dish scan result ready for diary logging (AGENTS.md §5.3).
class ScanResult {
  const ScanResult({
    required this.geometry,
    required this.items,
    required this.totalKcal,
    required this.totalMacros,
    required this.timings,
    required this.modelManifestVersion,
  });

  final PlateGeometry geometry;
  final List<DetectedItem> items;
  final Range totalKcal;
  final Macros totalMacros;
  final StageTimings timings;
  final String modelManifestVersion;

  @override
  String toString() =>
      'ScanResult(${items.length} items, totalKcal: ${totalKcal.p50} kcal, manifest: $modelManifestVersion)';
}
