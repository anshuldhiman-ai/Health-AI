"""Shared package init for the ML pipeline.

Layout (Section 4):
    src/ml_pipeline/
        data/       loaders, cleaning, dedupe, split, augmentations
        models/     timm wrappers, heads, distillation wrapper
        train/      train loop, losses, EMA, schedulers
        eval/       metrics, calibration, robustness, error analysis
        export/     to_litert.py, quantize.py, parity_test.py, model_card.py
        utils/
"""
