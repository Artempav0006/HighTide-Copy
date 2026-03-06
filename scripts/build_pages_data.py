#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
from typing import Any, Dict, Tuple


PAGE_CONTENT = """---
layout: page
title: "Design Metrics"
permalink: /design-metrics/
---

# Design Metrics

This page is generated from files under `designs/`.

| Technology | Design | Core Util | Macro Count | Latest .rpt Change (UTC) | Latest .rpt Path |
|-----------|--------|-----------|-------------|---------------------------|------------------|
{% raw %}{% for row in site.data.design_metrics %}{% endraw %}
| {% raw %}{{ row.technology }}{% endraw %} | {% raw %}{{ row.design }}{% endraw %} | {% raw %}{{ row.core_util | default: "N/A" }}{% endraw %} | {% raw %}{{ row.macro_count | default: "N/A" }}{% endraw %} | {% raw %}{{ row.latest_rpt_mtime_iso | default: "N/A" }}{% endraw %} | {% raw %}{{ row.latest_rpt_path | default: "N/A" }}{% endraw %} |
{% raw %}{% endfor %}{% endraw %}
"""


def load_json(path: Path) -> Any:
    if not path.exists():
        return []
    return json.loads(path.read_text())


def main() -> None:
    parser = argparse.ArgumentParser(description="Merge parsed metrics and write Jekyll data/page files.")
    parser.add_argument("--repo-root", default=".", help="Path to repo root")
    parser.add_argument(
        "--json-metrics",
        default="scripts/out/design_json_metrics.json",
        help="Input from parse_design_jsons.py"
    )
    parser.add_argument(
        "--rpt-times",
        default="scripts/out/design_rpt_times.json",
        help="Input from parse_rpt_mtimes.py"
    )
    parser.add_argument(
        "--docs-dir",
        default="docs copy",
        help="Path to Jekyll docs directory"
    )
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    json_metrics_path = repo_root / args.json_metrics
    rpt_times_path = repo_root / args.rpt_times
    docs_dir = repo_root / args.docs_dir

    if not docs_dir.exists():
        raise SystemExit(f"docs dir not found: {docs_dir}")

    json_metrics = load_json(json_metrics_path)
    rpt_times = load_json(rpt_times_path)

    merged: Dict[Tuple[str, str], Dict[str, Any]] = {}

    for row in json_metrics:
        key = (row["technology"], row["design"])
        merged[key] = dict(row)

    for row in rpt_times:
        key = (row["technology"], row["design"])
        if key not in merged:
            merged[key] = {
                "technology": row["technology"],
                "design": row["design"],
                "core_util": None,
                "macro_count": None,
                "json_sources": [],
            }
        merged[key].update({
            "latest_rpt_mtime_iso": row.get("latest_rpt_mtime_iso"),
            "latest_rpt_path": row.get("latest_rpt_path"),
            "report_count": row.get("report_count"),
        })

    output_rows = sorted(merged.values(), key=lambda r: (r["technology"], r["design"]))

    data_dir = docs_dir / "_data"
    data_dir.mkdir(parents=True, exist_ok=True)
    (data_dir / "design_metrics.json").write_text(json.dumps(output_rows, indent=2))

    page_path = docs_dir / "design-metrics.md"
    page_path.write_text(PAGE_CONTENT)

    print(f"Wrote {len(output_rows)} merged records to {data_dir / 'design_metrics.json'}")
    print(f"Wrote page template to {page_path}")


if __name__ == "__main__":
    main()
