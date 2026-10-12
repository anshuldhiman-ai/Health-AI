# ADR 0004: M0 smoke test — random-weights model through the converter

## Context

The ML stack (PyTorch → LiteRT Torch converter → `.tflite` →
`flutter_litert` in-app) is the riskiest integration in the project.
Waiting until M2 to discover that the chosen student architecture
converts or runs poorly on phones would waste the most expensive
resource: GPU hours.

## Decision

As part of M0, before any training:

1. Create a **randomly-initialized copy of each student candidate**
   (MobileNetV4 medium, EfficientNet-Lite0, MobileNetV3-Large) at the
   deployment input size.
2. Wrap it in the export module that bakes input normalisation into
   the graph and outputs logits.
3. Convert to FP32 `.tflite` with the LiteRT Torch converter
   (`litert-torch`), and run the Python parity check.
4. Load each `.tflite` in the app through the **inference isolate**
   and run one dummy inference.
5. Record per-candidate: conversion success, file size, and p50/p95
   latency on the low-end reference phone.

This is the "day-1 rule" from CLAUDE.md Section 8.7. Discover
conversion/runtime failures now, not after distillation.

## Consequences

- The ml/ pipeline, export module and app-side inference path are
  exercised end-to-end in M0, so M2 training lands on a proven path.
- The random-weights artifacts are throwaway; never committed (R8).

## Alternatives considered

- **Smoke test with a toy ConvNet** — cheaper, but does not surface
  architecture-specific converter issues (e.g. ops a candidate uses
  that LiteRT does not support).
- **Defer to M2** — the failure mode is discovering a bad architecture
  choice after spending GPU hours on it.
