# AI/ML Engineering: Health-AI

> **Document Type**: Machine Learning, Inference Pipeline & Volumetric Math Specification  
> **Source Repository**: `https://github.com/anshuldhiman-ai/Health-AI`  
> **Target Audience**: AI/ML Engineers, Computer Vision Engineers & Edge AI Developers  
> **Date**: 2026-11-03  

---

## 1. Machine Learning Pipeline Overview

Health-AI combines two on-device vision systems:
1. **Shipped Baseline Single-Dish Classifier** (`FoodRecognizer`): Lightweight MobileNetV4 model classifying 239 Indian dishes with distribution-aware uncertainty handling and Flip-TTA. *(Verified Implemented)*
2. **Multi-Dish Thali Vision & Volumetric Nutrition Engine** (`AGENTS.md` & `domain/services/`): Pure Dart geometry, 3D container modeling, and mass calculation engine designed for composite plates. *(Verified Implemented in Domain Layer; Model Export in Progress)*

```
┌────────────────────────────────────────────────────────────────────────┐
│                      OFFLINE ML TRAINING (Python)                      │
│   PyTorch + timm (MobileNetV4) ──► EMA Weights ──► Export to ONNX      │
│   ──► onnx2tf / litert-torch ──► Quantized baseline.tflite (INT8/FP32)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Bundled into app/assets/models/
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   ON-DEVICE INFERENCE ENGINE (Dart)                    │
│   Camera Still (XFile) ──► Background Isolate Preprocessing            │
│   (EXIF bake ──► Resize 255 ──► Center Crop 224 ──► Float32 NHWC)      │
│                                   │
│                                   ▼
│   flutter_litert Interpreter (4 Threads) ──► 239-Class Softmax Logits  │
│                                   │
│                                   ▼
│   TopConfidence Heuristic (Ratio top1/top2, Top-3 Mass Floor)          │
│   ├── If Ratio < 1.6: Execute Horizontal Flip TTA & Average            │
│   ├── If Top-1 < 0.15 & Mass < 0.48: Reject as Non-Food                │
│   └── If Ratio < 1.35 or Top-1 < 0.12: Flag Uncertain -> Show Top-3    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Region Segments & Bboxes
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                 DETERMINISTIC GEOMETRY & MASS ENGINE                   │
│   Plate Contour ──► RANSAC Ellipse Fit ──► Tilt θ + Metric Scale s     │
│   Container Profiles ──► Spherical Cap Bowl / Mound / Piece Models     │
│   MassEstimator ──► P10/P50/P90 Grams ──► NutritionCalculator (Atwater)│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Model Architecture, Training & Export

### Architecture Selection
- **Backbone**: MobileNetV4-Conv-Medium / Small (from `timm.create_model`).
- **Input Spec**: Single RGB image, shape `[1, 224, 224, 3]`, values normalized to `[0.0, 1.0]` float32 (ImageNet mean/std baked or applied in pipeline).
- **Head**: Linear projection to $N$ classes (80 in Khana baseline; 239 in expanded catalog).
- **Exponential Moving Average (EMA)**: `ModelEma` with decay factor 0.999 is tracked during training (`ml/src/ml_pipeline/models/classifier.py`); only EMA weights are exported.

### Export Pipeline (`ml/src/ml_pipeline/export/`)
- PyTorch checkpoint (`best.pt`) is converted to ONNX via `torch.onnx.export` with dynamic batching.
- ONNX is converted to LiteRT/TFLite via `onnx2tf` or Google's `litert-torch` (`ml/src/ml_pipeline/export/litert.py`).
- **Tiny-Model Export Smoke Test (`ml/src/ml_pipeline/export/smoke_test.py`)**: Runs on every GitHub Actions PR (`.github/workflows/ml-ci.yml`) using a tiny random-weights model to ensure conversion tools never silently break.

---

## 3. On-Device Preprocessing & Inference (`food_recognizer.dart`)

### Pure Dart Preprocessing (`preprocessFoodPhoto`)
Heavy image decoding and manipulation is offloaded to a background isolate:
1. **Orientation Baking**: `img.bakeOrientation(decoded)` respects EXIF rotation metadata (preventing landscape/portrait skew).
2. **Short-Side Resize**: Resizes shorter dimension to 255 pixels using bilinear interpolation (`img.Interpolation.linear`).
3. **Torchvision-Exact Center Crop**: Extracts a 224x224 bounding box centered within the resized image:
   ```dart
   final x0 = ((resized.width - _kImageSize) / 2).round();
   final y0 = ((resized.height - _kImageSize) / 2).round();
   final crop = img.copyCrop(resized, x: x0, y: y0, width: 224, height: 224);
   ```
4. **NHWC Tensor Packing**: Flattens pixels into a contiguous `Float32List(224 * 224 * 3)` with channels normalized to `[0.0, 1.0]`.

### Native LiteRT Execution
- Loaded via `Interpreter.fromAsset('assets/models/baseline.tflite', options: InterpreterOptions()..threads = 4)`.
- Input tensor: `[1, 224, 224, 3]` (float32).
- Output tensor: `[1, 239]` (float32 raw logits / probabilities).
- Serialized execution queue prevents concurrency issues in native C++ bindings.

---

## 4. Confidence Handling & Non-Food Gating

### Why Raw Probability is Misleading
In multi-class models (e.g. 239 classes), probability mass naturally disperses. A softmax top-1 probability of 0.35 in a 239-class model may indicate strong conviction, while 0.60 in a 10-class model might be ambiguous.

### The Ratio & Margin Strategy (`TopConfidence`)
Health-AI evaluates the **relative margin** between the winner and runner-up:
$$\text{ratio} = \frac{\text{top}_1}{\text{top}_2}$$

| Metric | Threshold | Interpretation | System Action |
| :--- | :--- | :--- | :--- |
| **TTA Threshold** | $\text{ratio} < 1.6$ | Top two classes are close | Runs horizontal-flip test-time augmentation (TTA) and averages both predictions. |
| **Uncertainty Threshold** | $\text{ratio} < 1.35 \lor \text{top}_1 < 0.12$ | Model cannot reliably separate classes | Flags `uncertain = true`. UI presents top-3 dish candidates with key ingredients for user confirmation. |
| **Non-Food Reject Gate** | $\text{top}_1 < 0.15 \land (\text{top}_3\text{Mass} < 0.48 \land \text{ratio} < 2.4)$ | Mass is thinly smeared across unrelated classes | Flags `isFood = false`. UI warns "Not a food item, please scan again or search manually." |

---

## 5. Pure Dart Geometry & Volumetric Engine

Located in `app/lib/domain/services/`, this engine runs 100% in Dart without any OpenCV, C++, or network dependencies.

### 1. Ellipse Fitting & Perspective Scale (`PlateGeometryCalculator`)
- **RANSAC 5-Point Subsets**: Randomly samples 5 contour points, fits conic parameters $A x^2 + B xy + C y^2 + D x + E y + F = 0$, evaluates inlier counts, and performs a least-squares refit on inliers.
- **Metric Scale Factor ($s$)**: Given known physical plate diameter $D$ (cm) and semi-major axis $a$ (pixels):
  $$s = \frac{D}{2a} \quad (\text{cm/px})$$
- **Camera Tilt Angle ($\theta_{\text{ell}}$)**: Derived from the semi-minor to semi-major ratio:
  $$\theta_{\text{ell}} = \arccos\left(\frac{b}{a}\right)$$
- **IMU Tilt Fusion**: Fuses optical tilt $\theta_{\text{ell}}$ with accelerometer gravity angle $\theta_{\text{imu}}$:
  - If $|\theta_{\text{imu}} - \theta_{\text{ell}}| \le 8^\circ$: $\theta = 0.5 \theta_{\text{imu}} + 0.5 \theta_{\text{ell}}$ (`conflict = false`).
  - Else: $\theta = \theta_{\text{imu}}$ (`conflict = true`).
  - If $\theta > 25^\circ$: UI displays capture tilt warning.
- **Real-World Surface Area ($A_{\text{cm}^2}$)**: Corrected for foreshortening:
  $$A_{\text{cm}^2} = \frac{N_{\text{pixels}} \cdot s^2}{\cos\theta}$$

### 2. 3D Volumetric Physics Models (`VolumetricMath`)
- **Spherical-Cap Bowl Model (Katoris)**:
  For a bowl of rim radius $a_c$ and depth $d_c$:
  $$R_{\text{sphere}} = \frac{a_c^2 + d_c^2}{2 d_c}$$
  $$r_s = \sqrt{\frac{A_{\text{surface}}}{\pi}} \quad (\text{clamped } r_s \le a_c)$$
  $$h = R_{\text{sphere}} - \sqrt{R_{\text{sphere}}^2 - r_s^2}$$
  $$V = \frac{\pi h^2 (3R_{\text{sphere}} - h)}{3}$$
- **Mound / Layer Model (Rice, Sabzi on plate)**:
  $$V = A_{\text{cm}^2} \times h_{\text{eff}}$$
- **Piece Mode (Roti, Idli, Samosa)**:
  $$m = n \times \text{unit\_mass} \times \text{clamp}\left(\frac{A_{\text{piece}}}{A_{\text{ref}}}, 0.6, 1.5\right)$$

### 3. Mass & Nutrition Range Estimation (`MassEstimator` & `NutritionCalculator`)
- **Confidence Ranges**: Mass is reported as $(P_{10}, P_{50}, P_{90})$ grams using empirical log-normal residual models:
  $$P_{x} = m_{\text{phys}} \times \exp(q_x)$$
- **Atwater Factor Validation**:
  $$\text{Atwater kcal} = 4 \times \text{Protein} + 4 \times \text{Carbs} + 9 \times \text{Fat}$$
  Must match catalog declared kcal within $\pm 12\%$.
- **Variant Adjustments**: Home light oil ($\Delta\text{fat} = -1.5\text{g}$) or restaurant rich ($\Delta\text{fat} = +3.5\text{g}$) adjust energy density by exactly $9.0\text{ kcal/g}$ fat delta.
- **Monte-Carlo Meal Total Aggregation**: 500-sample log-space simulation combining independent item uncertainties with a shared plate scale covariance term ($\sigma_{\text{scale}} = 0.05$).

### 4. Python ↔ Dart Parity Guard
All volumetric and mass formulas are implemented identically in both Python (`ml/src/ml_pipeline/mass/reference.py`) and Dart (`app/lib/domain/services/mass_estimator.dart`). Both implementations are continuously verified against `app/test/fixtures/mass_vectors.json`, ensuring numerical relative discrepancy $\le 10^{-6}$.
