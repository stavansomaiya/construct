#!/usr/bin/env python3
"""Benchmark Satark's offline rules on the public 120-row HF dataset."""
import csv
import html
import io
import json
from pathlib import Path
import subprocess
import sys
import urllib.request

URL = (
    "https://huggingface.co/datasets/karanverma19/"
    "Indian_Multilingual_Scam_Message_Dataset/resolve/main/"
    "ultra_premium_scam_dataset.csv"
)


def main():
    with urllib.request.urlopen(URL, timeout=30) as response:
        source = response.read().decode("utf-8-sig")
    rows = list(csv.DictReader(io.StringIO(source)))
    required = {"message", "label", "language"}
    if not rows or not required.issubset(rows[0]):
        raise SystemExit(f"Unexpected CSV schema. Expected columns: {sorted(required)}")
    for row in rows:
        row["label"] = row["label"].strip().lower()
        if row["label"] not in {"scam", "legit"}:
            raise SystemExit(f"Unexpected label: {row['label']!r}")

    result = subprocess.run(
        [
            ".tooling/flutter/bin/dart",
            "scripts/benchmark_rules.dart",
        ],
        input=json.dumps(rows, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    report = {
        "dataset": "karanverma19/Indian_Multilingual_Scam_Message_Dataset",
        "source": URL,
        "license": "Apache-2.0 (as declared by the dataset card)",
        "rule": "Any Satark risk except low_indicators counts as flagged scam.",
        "metrics": json.loads(result.stdout),
    }
    metrics = report["metrics"]
    pct = lambda number: f"{number * 100:.1f}%"
    language_rows = "".join(
        "<tr>"
        f"<td>{html.escape(language)}</td><td>{stats['total']}</td>"
        f"<td>{stats['scams']}</td><td>{stats['tp']}</td>"
        f"<td>{stats['fp']}</td><td>{stats['fn']}</td>"
        f"<td>{pct(stats['recall'])}</td></tr>"
        for language, stats in metrics["languages"].items()
    )
    html_report = f"""<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width">
<title>Satark dataset evaluation</title>
<style>
body{{font:16px/1.55 system-ui,sans-serif;color:#202744;background:#f7f6f0;max-width:900px;margin:32px auto;padding:0 20px}}
h1,h2{{color:#171b3b}} .card{{background:white;border:1px solid #e8e8e2;border-radius:16px;padding:20px;margin:16px 0}}
.metrics{{display:grid;grid-template-columns:repeat(auto-fit,minmax(130px,1fr));gap:12px}}
.metric{{background:#eef5f3;border-radius:12px;padding:14px}} .value{{font-size:1.5rem;font-weight:750;color:#13877d}}
table{{border-collapse:collapse;width:100%;font-size:.93rem}} th,td{{border-bottom:1px solid #e8e8e2;padding:9px;text-align:left}}
a{{color:#13877d;overflow-wrap:anywhere}} .note{{color:#555e73}}
</style>
<h1>Satark rule-checker evaluation</h1>
<p class="note">Offline benchmark against a public labeled multilingual message dataset. This evaluates the current rules, not a trained model.</p>
<section class="card"><h2>Overall ({metrics['total']} messages)</h2><div class="metrics">
<div class="metric"><div>Accuracy</div><div class="value">{pct(metrics['accuracy'])}</div></div>
<div class="metric"><div>Precision</div><div class="value">{pct(metrics['precision'])}</div></div>
<div class="metric"><div>Recall</div><div class="value">{pct(metrics['recall'])}</div></div>
<div class="metric"><div>F1</div><div class="value">{pct(metrics['f1'])}</div></div>
</div><p>True positives: {metrics['tp']} · False positives: {metrics['fp']} · True negatives: {metrics['tn']} · False negatives: {metrics['fn']}</p></section>
<section class="card"><h2>By language</h2><table><thead><tr><th>Language</th><th>Samples</th><th>Scams</th><th>Correctly flagged</th><th>False alarms</th><th>Missed scams</th><th>Scam recall</th></tr></thead><tbody>{language_rows}</tbody></table></section>
<section class="card"><h2>Method and limits</h2>
<p>“Scam flagged” means Satark returned review or high risk; low indicators counts as not flagged. Precision/recall/F1 treat scam as the positive class. Messages were analyzed with the English output setting; the checker still scans Hindi and Latin-script patterns.</p>
<p>The dataset card describes 120 Hindi, Hinglish, and English samples and declares an Apache-2.0 license. This small dataset is a smoke-test benchmark, not an independent or representative measure of real-world performance. Synthetic/curated message distributions, label quality, and rule overlap can strongly affect results; scores do not establish safety or generalization.</p>
<p>Dataset: <a href="https://huggingface.co/datasets/karanverma19/Indian_Multilingual_Scam_Message_Dataset">karanverma19/Indian_Multilingual_Scam_Message_Dataset</a></p>
<p>Reproduce from the project root with <code>python3 scripts/evaluate_dataset.py</code>.</p></section>
</html>"""
    output = Path("generated-artifacts/benchmark-report.html")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(html_report, encoding="utf-8")
    print(json.dumps({**report, "report": str(output)}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (OSError, UnicodeError, json.JSONDecodeError, subprocess.CalledProcessError) as exc:
        print(f"Benchmark failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
