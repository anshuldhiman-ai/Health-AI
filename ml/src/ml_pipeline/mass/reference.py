"""Python reference implementation of the Health AI Volumetric Mass Engine (AGENTS.md §6.2).

Matches Dart implementation in app/lib/domain/services/mass_estimator.dart.
Both must pass app/test/fixtures/mass_vectors.json with relative error <= 1e-6.
"""

import math
from typing import Dict, Any, Tuple

def bowl_volume(surface_area_cm2: float, rim_radius_cm: float, depth_cm: float) -> float:
    """Calculates spherical-cap bowl volume in ml (cm³)."""
    if surface_area_cm2 <= 0.0 or rim_radius_cm <= 0.0 or depth_cm <= 0.0:
        return 0.0

    # R = (a_c² + d_c²) / (2·d_c)
    sphere_r = (rim_radius_cm**2 + depth_cm**2) / (2.0 * depth_cm)
    
    # r_s = sqrt(A / pi), clamped <= rim_radius
    raw_rs = math.sqrt(surface_area_cm2 / math.pi)
    rs = min(raw_rs, rim_radius_cm)
    
    # h = R - sqrt(R² - r_s²)
    under = max(0.0, sphere_r**2 - rs**2)
    h = sphere_r - math.sqrt(under)
    
    # V = pi * h² * (3R - h) / 3
    return (math.pi * h**2 * (3.0 * sphere_r - h)) / 3.0

def mound_volume(area_cm2: float, effective_height_cm: float) -> float:
    """Calculates food mound volume on flat plate in ml (cm³)."""
    if area_cm2 <= 0.0 or effective_height_cm <= 0.0:
        return 0.0
    return area_cm2 * effective_height_cm

def piece_mass(
    count: int,
    unit_mass_g: float,
    piece_area_cm2: float | None = None,
    reference_piece_area_cm2: float | None = None,
) -> float:
    """Calculates mass for piece-mode food item with area ratio clamp [0.6, 1.5]."""
    if count <= 0 or unit_mass_g <= 0.0:
        return 0.0

    scale = 1.0
    if (
        piece_area_cm2 is not None
        and reference_piece_area_cm2 is not None
        and reference_piece_area_cm2 > 0.0
        and piece_area_cm2 > 0.0
    ):
        raw_ratio = piece_area_cm2 / reference_piece_area_cm2
        scale = max(0.6, min(1.5, raw_ratio))

    return count * unit_mass_g * scale

def estimate_quantiles(
    mass_phys_g: float,
    q10: float = -0.25,
    q50: float = 0.0,
    q90: float = 0.25,
    calibration_factor: float = 1.0,
) -> Tuple[float, float, float]:
    """Applies calibration factor and returns (P10, P50, P90) mass ranges."""
    base = mass_phys_g * calibration_factor
    p10 = base * math.exp(q10)
    p50 = base * math.exp(q50)
    p90 = base * math.exp(q90)
    return p10, p50, p90
