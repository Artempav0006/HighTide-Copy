#!/usr/bin/env python3
import argparse
import json
from datetime import datetime, UTC
from pathlib import Path
from typing import Any, Dict, Tuple


def infer_design_info(rpt_path: Path, designs_dir: Path) -> Tuple[str, str]:
    rel = rpt_path.relative_to(designs_dir)
    parts = rel.parts

    if not parts:
        return "unknown", rpt_path.stem

    if parts[0] == "src":
        tech = "src"
        design = parts[1] if len(parts) > 1 else rpt_path.stem
        return tech, design

    tech = parts[0]
    design = parts[1] if len(parts) > 1 else rpt_path.stem
    return tech, design


def main() -> None:
    parser = argparse.ArgumentParser(description="Parse .rpt files in designs/ for latest modified time.")
    parser.add_argument("--repo-root", default=".", help="Path to repo root")
    parser.add_argument(
        "--output",
        default="scripts/out/design_rpt_times.json",
        help="Output JSON file"
    )
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    designs_dir = repo_root / "designs"
    out_path = (repo_root / args.output).resolve()

    if not designs_dir.exists():
        raise SystemExit(f"designs directory not found: {designs_dir}")

    records: Dict[Tuple[str, str], Dict[str, Any]] = {}

    for rpt_file in designs_dir.rglob("*.rpt"):
        tech, design = infer_design_info(rpt_file, designs_dir)
        mtime = rpt_file.stat().st_mtime
        mtime_iso = datetime.fromtimestamp(mtime, UTC).isoformat()

        key = (tech, design)
        current = records.get(key, {
            "technology": tech,
            "design": design,
            "latest_rpt_mtime": None,
            "latest_rpt_mtime_iso": None,
            "latest_rpt_path": None,
            "report_count": 0,
        })

        current["report_count"] += 1

        if current["latest_rpt_mtime"] is None or mtime > current["latest_rpt_mtime"]:
            current["latest_rpt_mtime"] = mtime
            current["latest_rpt_mtime_iso"] = mtime_iso
            current["latest_rpt_path"] = str(rpt_file.relative_to(repo_root))

        records[key] = current

    for rec in records.values():
        rec.pop("latest_rpt_mtime", None)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    output = sorted(records.values(), key=lambda r: (r["technology"], r["design"]))
    out_path.write_text(json.dumps(output, indent=2))
    print(f"Wrote {len(output)} records to {out_path}")


if __name__ == "__main__":
    main()
