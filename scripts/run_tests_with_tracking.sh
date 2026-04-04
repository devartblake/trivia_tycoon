#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="${1:-artifacts/test_reports}"
mkdir -p "${REPORT_DIR}"

MACHINE_LOG="${REPORT_DIR}/flutter_test_machine.log"
SUMMARY_JSON="${REPORT_DIR}/flutter_test_summary.json"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH; cannot execute test run." >&2
  exit 127
fi

echo "Running flutter tests with machine-readable output..."
flutter test --machine | tee "${MACHINE_LOG}"

python3 - <<'PY' "${MACHINE_LOG}" "${SUMMARY_JSON}"
import json, sys
machine_log = sys.argv[1]
summary_path = sys.argv[2]

passed = failed = errors = skipped = 0
suite = 0

with open(machine_log, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        t = event.get("type")
        if t == "suite":
            suite += 1
        elif t == "testDone":
            result = event.get("result")
            hidden = bool(event.get("hidden", False))
            if hidden:
                continue
            if result == "success":
                passed += 1
            elif result == "failure":
                failed += 1
            elif result == "error":
                errors += 1
            elif result == "skipped":
                skipped += 1

summary = {
    "suites_seen": suite,
    "passed": passed,
    "failed": failed,
    "errors": errors,
    "skipped": skipped,
    "total_visible": passed + failed + errors + skipped,
    "status": "pass" if failed == 0 and errors == 0 else "fail",
}

with open(summary_path, "w", encoding="utf-8") as out:
    json.dump(summary, out, indent=2)

print(json.dumps(summary, indent=2))
PY

echo "Saved:"
echo "  - ${MACHINE_LOG}"
echo "  - ${SUMMARY_JSON}"
