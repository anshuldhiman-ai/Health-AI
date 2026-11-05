# Numerical estimation and cross-language parity

## Define units and assumptions

Every public calculation should document:

- Input units
- Output units
- Valid ranges
- Assumptions and geometry model
- Invalid-input behavior
- Sources of uncertainty
- Calibration provenance

Keep pure math in a deterministic domain module.

## Example model families

A mobile food-portion estimator may use:

- Bowl/container volume from a geometric profile
- Plate mound volume from observed area and an effective-height prior
- Piece count multiplied by a unit-mass prior
- Density to convert volume to mass
- Per-100g nutrient values to scale calories and macros

These are estimation models, not direct measurements. Their assumptions must be visible to the user and validated against weighed samples.

## Ranges and calibration

- Use P10/P50/P90 or another clearly defined interval when inputs are uncertain.
- Mark unmeasured density, height, and calibration factors as placeholders.
- Fit calibration only on training data and evaluate on held-out plates/sessions.
- Report bias, median absolute error, interval coverage, and worst-case examples.
- Avoid presenting a range as statistically calibrated unless the validation procedure supports that claim.

## Cross-language parity

When Python is used for calibration/training and Dart for production:

1. Define a shared JSON fixture with named test vectors.
2. Include normal, boundary, invalid, and degenerate inputs.
3. Compare outputs using a documented absolute/relative tolerance.
4. Test both explicit parameters and function defaults.
5. Keep unit conversion and rounding rules identical.
6. Seed randomness for deterministic tests.
7. Run both language test suites in CI.

A shared fixture is stronger than duplicated handwritten examples, but it does not prove runtime model parity or real-world estimation accuracy.
