# On-device ML and computer vision

## Model contract

Record and validate:

- Model identifier, version, checksum, and provenance
- Input shape and batch size
- Data type and quantization parameters
- Layout (NHWC/NCHW)
- Channel order (RGB/BGR)
- Pixel range and normalization
- Resize, crop, interpolation, and EXIF orientation
- Output tensor shape and meaning (logits/probabilities/embeddings/masks)
- Exact label order and mapping
- Runtime and delegate requirements

Fail model loading if the contract does not match. A shape-compatible tensor can still be semantically wrong if preprocessing or label order differs.

## Preprocessing parity

The training and mobile pipelines must be compared using fixed input images and numerical outputs. Do not assume two libraries' resize or crop implementations are identical.

A robust parity suite should cover:

- Portrait and landscape images
- EXIF-rotated photos
- Non-square dimensions
- Alpha-channel inputs if accepted
- Low-light and high-resolution inputs
- Channel order and normalization
- Resize/crop edge cases

If native image decoding/downscaling is available, benchmark it against full-resolution decoding in a worker isolate. Measure peak memory as well as latency.

## Runtime lifecycle

- Create and dispose interpreters deterministically.
- Keep native handles inside the isolate/thread that owns them if the runtime requires it.
- Serialize calls unless concurrent execution is explicitly supported.
- Warm up only when the UX and memory budget justify it.
- Apply timeouts and convert runtime exceptions into typed failures.
- Avoid repeated model loads between scans.
- Test model missing, corrupt, incompatible, and out-of-memory paths.

## Confidence and rejection

- Calibrate confidence on representative data from the intended deployment domain.
- Include hard negatives (non-food, clutter, packaging, pets, backgrounds) for food recognition.
- A top-1/top-2 ratio is a useful ambiguity signal, not a calibrated probability of correctness.
- A top-k mass heuristic is not a substitute for a trained reject class or out-of-distribution evaluation.
- Run test-time augmentation only when it provides measured value; account for its latency cost.
- Ask the user to confirm uncertain predictions and preserve manual entry/search.

Unit tests can validate threshold logic. Only a labelled validation set can validate threshold quality.

## Model cards and distribution

For every shipped model, document:

- Intended use and prohibited use
- Architecture and input/output contract
- Training datasets, licenses, and provenance
- Pretrained weights and licenses
- Train/validation/test split method
- Metrics and calibration procedure
- Device latency and memory
- Quantization and parity results
- Known failure modes
- Version/hash and reproducibility information

Never ship weights derived from datasets whose terms prohibit commercial redistribution. Treat code, pretrained weights, datasets, and derived model weights as separate licensing questions.
