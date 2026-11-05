# Workflow: debug a failing or misleading release gate

## 1. Follow the workflow wiring

Open the CI YAML and trace each command, working directory, environment variable, artifact path, and exit code.

## 2. Confirm the test is discoverable

Check test naming conventions and whether a module invocation actually calls the test function. Inspect `__main__` blocks and test-runner output.

## 3. Validate artifact paths

For APK/AAB/IPA, verify the actual archive structure and use the correct inspection tool. Avoid scripts that assume an internal file path without testing it against a real artifact.

## 4. Test the gate itself

Introduce a safe temporary fixture or deliberate test failure and confirm the gate fails. Revert the fixture afterward.

## 5. Distinguish gate status

- Script exists
- Script is called in CI
- Script reaches the intended code
- Script has passed on current commit
- Script validates the final artifact

These are five different states. Report the exact one supported by evidence.
