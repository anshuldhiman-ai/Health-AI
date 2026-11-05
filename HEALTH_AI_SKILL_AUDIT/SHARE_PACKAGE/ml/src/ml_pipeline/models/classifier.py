"""Model factory (Section 8.7): timm backbones, mobile-first.

Student candidates: MobileNetV4 conv medium, EfficientNet-Lite0-2,
MobileNetV3-Large. Day-1 rule: export a RANDOM-WEIGHTS copy of every
candidate through the converter before spending GPU hours (Section
8.7) — pretrained=True only after that check passes.
"""

from __future__ import annotations

import torch
import torch.nn as nn


def build_model(
    model_name: str,
    num_classes: int,
    pretrained: bool = True,
    drop_rate: float = 0.1,
) -> nn.Module:
    """timm classifier with a fresh head for our class list."""
    import timm

    return timm.create_model(
        model_name,
        pretrained=pretrained,
        num_classes=num_classes,
        drop_rate=drop_rate,
    )


class ModelEma(nn.Module):
    """Exponential moving average of weights (Section 8.7.5).

    The EMA copy is what gets exported (more stable under LR noise).
    Construct with [build_ema]; never re-instantiate the wrapped model
    (timm models need their kwargs, deepcopy is always safe).
    """

    def __init__(self, source: nn.Module, decay: float = 0.999) -> None:
        super().__init__()
        self.decay = decay
        self.module = _deep_copy_model(source)

    @torch.no_grad()
    def update(self, model: nn.Module) -> None:
        for ema_p, p in zip(
            self.module.state_dict().values(),
            model.state_dict().values(),
            strict=True,
        ):
            if p.dtype.is_floating_point:
                ema_p.mul_(self.decay).add_(p.detach(), alpha=1 - self.decay)
            else:
                ema_p.copy_(p)


def build_ema(model: nn.Module, decay: float) -> ModelEma:
    return ModelEma(model, decay=decay)


def _deep_copy_model(model: nn.Module) -> nn.Module:
    import copy

    return copy.deepcopy(model).eval()
