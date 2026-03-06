#!/usr/bin/env python3
import argparse
import json
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple


CORE_UTIL_KEYS = {
    "core_util",
    "core_utilization",
    "core_util_pct",
    "core_util_percent",
    "utilization",
    "util_pct",
}

MACRO_COUNT_KEYS = {
    "macro_count",
    "macros_count",
    "num_macros",
    "macro_cnt",
}

MACRO_CONTAINER_KEYS = {
    "macros",
    "macro_instances",
    "macro_list",
}


def iter_nodes(obj: Any, path: str = "") -> Iterable[Tuple[str, Any]]:
    if isinstance(obj, dict):
        for k, v in obj.items():
            new_path = f"{path}.{k}" if path else k
            yield new_path, v
            yield from iter_nodes(v, new_path)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            new_path = f"{path}[{i}]"
            yield new_path, v
            yield from iter_nodes(v, new_path)


def to_number(value: Any) -> Optional[float]:
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        s = value.strip().replace("%", "")
        try:
            return float(s)
        except ValueError:
            return None
    return None


def infer_design_info(json_path: Path, designs_dir: Path) -> Tuple[str, str]:
    rel = json_path.relative_to(designs_dir)
    parts = rel.parts

    if not parts:
        return "unknown", json_path.stem

    if parts[0] == "src":
        tech = "src"
        design = parts[1] if len(parts) > 1 else json_path.stem
        return tech, design

    tech = parts[0]
    design = parts[1] if len(parts) > 1 else json_path.stem
    return tech, design


def extract_metrics(data: Any) -> Dict[str, Any]:
    core_util = None
    macro_count = None
    macro_sources: List[str] = []

    for path, value in iter_nodes(data):
        key = path.split(".")[-1]
        key = key.split("[")[0].lower()

        if core_util is None and key in CORE_UTIL_KEYS:
            num = to_number(value)
            if num is not None:
                core_util = num

        if macro_count is None and key in MACRO_COUNT_KEYS:
            num = to_number(value)
            if num is not None:
                macro_count = int(num)

        if key in MACRO_CONTAINER_KEYS:
            if isinstance(value, list):
                macro_count = len(value)
                macro_sources.append(path)
            elif isinstance(value, dict):
                macro_count = len(value.keys())
                macro_sources.append(path)

    return {
        "core_util": core_util,
        "macro_count": macro_count,
        "macro_sources": macro_sources,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Parse JSON files in designs/ for core util and macro data.")
    parser.add_argument("--repo-root", default=".", help="Path to repo root")
    parser.add_argument(
        "--output",
        default="scripts/out/design_json_metrics.json",
        help="Output JSON file"
    )
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    designs_dir = repo_root / "designs"
    out_path = (repo_root / args.output).resolve()

    if not designs_dir.exists():
        raise SystemExit(f"designs directory not found: {designs_dir}")

    records: Dict[Tuple[str, str], Dict[str, Any]] = {}

    for json_file in designs_dir.rglob("*.json"):
        try:
            data = json.loads(json_file.read_text())
        except Exception:
            continue

        tech, design = infer_design_info(json_file, designs_dir)
        metrics = extract_metrics(data)

        if metrics["core_util"] is None and metrics["macro_count"] is None:
            continue

        key = (tech, design)
        current = records.get(key, {
            "technology": tech,
            "design": design,
            "core_util": None,
            "macro_count": None,
            "json_sources": [],
        })

        if current["core_util"] is None and metrics["core_util"] is not None:
            current["core_util"] = metrics["core_util"]

        if current["macro_count"] is None and metrics["macro_count"] is not None:
            current["macro_count"] = metrics["macro_count"]

        current["json_sources"].append(str(json_file.relative_to(repo_root)))
        records[key] = current

    out_path.parent.mkdir(parents=True, exist_ok=True)
    output = sorted(records.values(), key=lambda r: (r["technology"], r["design"]))
    out_path.write_text(json.dumps(output, indent=2))
    print(f"Wrote {len(output)} records to {out_path}")


if __name__ == "__main__":
    main()
