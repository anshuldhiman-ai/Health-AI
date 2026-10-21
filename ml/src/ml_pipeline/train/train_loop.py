"""Training loop (Section 8.6/8.7).

Rules honoured here:
  - checkpoint EVERY epoch to persistent storage + --resume, because
    free GPU sessions die mid-run (Section 8.6)
  - every checkpoint carries config, git commit, seed, epoch
  - AMP mixed precision; AdamW; cosine schedule with warmup
  - label smoothing 0.1; EMA of weights; the EMA model is exported
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import torch
from torch.utils.data import DataLoader
from tqdm import tqdm

from ml_pipeline.eval.metrics import topk_accuracy
from ml_pipeline.models.classifier import build_ema
from ml_pipeline.utils.seeding import git_commit


def gpu_mem_gb(device: torch.device | None = None) -> float:
    """Peak GPU memory allocated in GiB (YOLO-style GPU_mem column)."""
    if not torch.cuda.is_available():
        return 0.0
    return torch.cuda.max_memory_allocated(device) / (1024**3)


def lr_lambda_factory(warmup_epochs: int, total_epochs: int):
    def lr_lambda(step: int) -> float:
        steps_per_epoch_hint = 1  # stepped per epoch
        epoch = step * steps_per_epoch_hint
        if epoch < warmup_epochs:
            return (epoch + 1) / max(1, warmup_epochs)
        progress = (epoch - warmup_epochs) / max(1, total_epochs - warmup_epochs)
        return 0.5 * (1 + math.cos(math.pi * min(1.0, progress)))

    return lr_lambda


def save_checkpoint(
    path: Path,
    model: torch.nn.Module,
    ema_module: torch.nn.Module | None,
    optimizer,
    scheduler,
    epoch: int,
    meta: dict,
    best_top1: float | None = None,
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    torch.save(
        {
            "model": model.state_dict(),
            "ema": None if ema_module is None else ema_module.state_dict(),
            "optimizer": optimizer.state_dict(),
            "scheduler": scheduler.state_dict(),
            "epoch": epoch,
            "meta": meta,
            "best_top1": best_top1,
        },
        path,
    )


def load_checkpoint(path: Path, model, optimizer, scheduler, ema=None):
    ckpt = torch.load(path, map_location="cpu", weights_only=False)
    model.load_state_dict(ckpt["model"])
    optimizer.load_state_dict(ckpt["optimizer"])
    scheduler.load_state_dict(ckpt["scheduler"])
    if ema is not None and ckpt.get("ema"):
        # ckpt["ema"] holds the INNER model's state (saved as
        # ema.module.state_dict()); load it into the inner module,
        # not the ModelEma wrapper.
        ema.module.load_state_dict(ckpt["ema"])
    best_top1 = ckpt.get("best_top1")
    if best_top1 is None:
        best_top1 = (ckpt.get("meta") or {}).get("best_top1")
    return ckpt["epoch"], ckpt.get("meta", {}), best_top1


@torch.no_grad()
def evaluate(model, loader, device, num_classes: int, desc: str = "val") -> dict:
    model.eval()
    logits_all: list[torch.Tensor] = []
    targets_all: list[torch.Tensor] = []
    bar = tqdm(loader, desc=desc, leave=False, unit="it")
    for images, targets in bar:
        images = images.to(device, non_blocking=True)
        out = model(images)
        logits_all.append(out.cpu())
        targets_all.append(targets)
        bar.set_postfix(top1=f"{topk_accuracy(out.cpu(), targets, 1):.3f}")
    logits = torch.cat(logits_all)
    targets = torch.cat(targets_all)
    return {
        "top1": topk_accuracy(logits, targets, 1),
        "top5": topk_accuracy(logits, targets, 5),
        "n": int(targets.numel()),
    }


def fit(
    model: torch.nn.Module,
    train_loader: DataLoader,
    val_loader: DataLoader,
    num_classes: int,
    out_dir: Path,
    epochs: int = 30,
    warmup_epochs: int = 3,
    lr: float = 1e-3,
    weight_decay: float = 0.05,
    label_smoothing: float = 0.1,
    ema_decay: float = 0.999,
    amp: bool = True,
    seed: int = 42,
    resume_from: Path | None = None,
) -> Path:
    """Train, checkpointing every epoch; returns the best-EMA checkpoint."""
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model.to(device)
    ema = build_ema(model, ema_decay)
    ema.to(device)

    criterion = torch.nn.CrossEntropyLoss(label_smoothing=label_smoothing)
    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=weight_decay)
    scheduler = torch.optim.lr_scheduler.LambdaLR(
        optimizer, lr_lambda_factory(warmup_epochs, epochs)
    )
    scaler = torch.amp.GradScaler("cuda", enabled=amp and device.type == "cuda")

    meta = {"git_commit": git_commit(), "seed": seed, "num_classes": num_classes}
    start_epoch = 0
    resumed_best_top1 = None
    if resume_from and Path(resume_from).exists():
        start_epoch, loaded_meta, resumed_best_top1 = load_checkpoint(
            resume_from, model, optimizer, scheduler, ema
        )
        if loaded_meta:
            meta.update({k: v for k, v in loaded_meta.items() if k not in meta})
        print(f"resumed from {resume_from} at epoch {start_epoch}")

    best_path = out_dir / "best.pt"
    out_dir.mkdir(parents=True, exist_ok=True)
    best_ckpt_path = Path(resume_from) if (resume_from and Path(resume_from).exists()) else best_path

    # Establish the best-so-far bar so a resumed run never clobbers a
    # better earlier checkpoint on the first epoch. Prefer a value stored
    # in the checkpoint; otherwise evaluate the restored model once.
    if resumed_best_top1 is not None:
        best_top1 = float(resumed_best_top1)
    elif start_epoch > 0:
        restored_metrics = evaluate(model, val_loader, device, num_classes, desc="resume-val")
        best_top1 = float(restored_metrics["top1"])
        print(f"resume baseline val top1 = {best_top1:.4f}")
    else:
        best_top1 = -1.0

    for epoch in range(start_epoch, epochs):
        model.train()
        running_loss, seen = 0.0, 0
        bar = tqdm(
            train_loader,
            desc=f"  epoch {epoch + 1}/{epochs}",
            leave=True,
            unit="it",
        )
        for step, (images, targets) in enumerate(bar):
            images = images.to(device, non_blocking=True)
            targets = targets.to(device, non_blocking=True)
            optimizer.zero_grad(set_to_none=True)
            with torch.amp.autocast("cuda", enabled=scaler.is_enabled()):
                loss = criterion(model(images), targets)
            scaler.scale(loss).backward()
            scaler.unscale_(optimizer)
            torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            scaler.step(optimizer)
            scaler.update()
            ema.update(model)
            running_loss += loss.item() * targets.numel()
            seen += targets.numel()
            if step % 25 == 0 or step == len(bar) - 1:
                bar.set_postfix(
                    loss=f"{loss.item():.3f}",
                    gpu_mem=f"{gpu_mem_gb():.2f}G",
                    refresh=True,
                )
        scheduler.step()

        metrics = evaluate(model, val_loader, device, num_classes)
        record = {
            "epoch": epoch,
            "train_loss": running_loss / max(1, seen),
            "lr": scheduler.get_last_lr()[0],
            **metrics,
        }
        # machine-readable line (metrics.jsonl + logs) AND the
        # YOLO-style human line below.
        print(json.dumps(record))
        print(
            f"   Epoch   GPU_mem     loss     top1     top5\n"
            f"   {epoch + 1}/{epochs:<4}   "
            f"{gpu_mem_gb():.2f}G   "
            f"{record['train_loss']:.4f}   "
            f"{metrics['top1']:.4f}   {metrics['top5']:.4f}"
        )
        with open(out_dir / "metrics.jsonl", "a", encoding="utf-8") as f:
            f.write(json.dumps(record) + "\n")

        meta["best_top1"] = best_top1
        save_checkpoint(
            out_dir / "last.pt",
            model,
            ema.module,
            optimizer,
            scheduler,
            epoch + 1,
            meta,
            best_top1=best_top1,
        )
        if metrics["top1"] > best_top1:
            best_top1 = metrics["top1"]
            meta["best_top1"] = best_top1
            save_checkpoint(
                best_path,
                model,
                ema.module,
                optimizer,
                scheduler,
                epoch + 1,
                meta,
                best_top1=best_top1,
            )
            best_ckpt_path = best_path
    return best_ckpt_path
