"""Tests Python reference mass engine against test vectors (AGENTS.md §6.3, T5.3)."""

import json
from pathlib import Path
from ml_pipeline.mass.reference import bowl_volume, mound_volume, piece_mass, estimate_quantiles

FIXTURES_PATH = Path(__file__).resolve().parents[2] / "app" / "test" / "fixtures" / "mass_vectors.json"

def test_mass_vectors_parity_python():
    with open(FIXTURES_PATH, encoding="utf-8") as f:
        vectors = json.load(f)

    for vec in vectors:
        mode = vec["mode"]
        if mode == "bowl":
            vol = bowl_volume(
                surface_area_cm2=vec["surface_area_cm2"],
                rim_radius_cm=vec["rim_radius_cm"],
                depth_cm=vec["depth_cm"],
            )
            assert abs(vol - vec["expected_volume_ml"]) / vec["expected_volume_ml"] <= 1e-6
            mass_phys = vol * vec["density_g_per_ml"]
            assert abs(mass_phys - vec["expected_mass_phys_g"]) / vec["expected_mass_phys_g"] <= 1e-6

            p10, p50, p90 = estimate_quantiles(
                mass_phys_g=mass_phys,
                q10=vec["residual_q10"],
                q50=vec["residual_q50"],
                q90=vec["residual_q90"],
            )
            assert abs(p10 - vec["expected_p10_g"]) / vec["expected_p10_g"] <= 1e-6
            assert abs(p50 - vec["expected_p50_g"]) / vec["expected_p50_g"] <= 1e-6
            assert abs(p90 - vec["expected_p90_g"]) / vec["expected_p90_g"] <= 1e-6

        elif mode == "mound":
            p10_vol = mound_volume(vec["area_cm2"], vec["h_eff_p10_cm"])
            p50_vol = mound_volume(vec["area_cm2"], vec["h_eff_p50_cm"])
            p90_vol = mound_volume(vec["area_cm2"], vec["h_eff_p90_cm"])

            p10 = p10_vol * vec["density_g_per_ml"]
            p50 = p50_vol * vec["density_g_per_ml"]
            p90 = p90_vol * vec["density_g_per_ml"]

            assert abs(p10 - vec["expected_p10_g"]) / vec["expected_p10_g"] <= 1e-6
            assert abs(p50 - vec["expected_p50_g"]) / vec["expected_p50_g"] <= 1e-6
            assert abs(p90 - vec["expected_p90_g"]) / vec["expected_p90_g"] <= 1e-6

        elif mode == "piece":
            mass = piece_mass(
                count=vec["count"],
                unit_mass_g=vec["unit_mass_g"],
                piece_area_cm2=vec["piece_area_cm2"],
                reference_piece_area_cm2=vec["reference_piece_area_cm2"],
            )
            p10, p50, p90 = estimate_quantiles(
                mass_phys_g=mass,
                q10=vec["residual_q10"],
                q50=vec["residual_q50"],
                q90=vec["residual_q90"],
            )
            assert abs(p10 - vec["expected_p10_g"]) / vec["expected_p10_g"] <= 1e-6
            assert abs(p50 - vec["expected_p50_g"]) / vec["expected_p50_g"] <= 1e-6
            assert abs(p90 - vec["expected_p90_g"]) / vec["expected_p90_g"] <= 1e-6
