#!/usr/bin/env python3
"""Analyze benchmark results and generate summary."""

import json
import os
import statistics
import sys
from pathlib import Path


def load_results(results_dir: str) -> dict:
    """Load all JSON result files from the results directory."""
    results = {}
    results_path = Path(results_dir)

    for json_file in results_path.glob("*.json"):
        with open(json_file) as f:
            data = json.load(f)
            lang = data["language"]
            results[lang] = data

    return results


def analyze(results: dict) -> None:
    """Analyze and print benchmark results."""
    if not results:
        print("No results found!")
        return

    # Calculate medians for each language
    summaries = []
    for lang, data in results.items():
        direct_median = statistics.median(data["direct_ms"])
        inverse_median = statistics.median(data["inverse_ms"])
        summaries.append({
            "language": lang,
            "version": data["version"],
            "library": data["library"],
            "library_version": data["library_version"],
            "test_cases": data["test_cases"],
            "runs": data["runs"],
            "direct_median": direct_median,
            "inverse_median": inverse_median,
        })

    # Sort by direct median time
    summaries.sort(key=lambda x: x["direct_median"])

    # Print header
    print("\n" + "=" * 80)
    print("GeographicLib Benchmark Results")
    print("=" * 80)
    print(f"\nTest cases: {summaries[0]['test_cases']:,}")
    print(f"Runs per benchmark: {summaries[0]['runs']}")

    # Print Direct results
    print("\n" + "-" * 40)
    print("Direct (geodesic forward problem)")
    print("-" * 40)
    print(f"{'Language':<10} {'Median (ms)':<12} {'Relative':<10} {'Library'}")
    print("-" * 60)

    baseline = summaries[0]["direct_median"]
    for s in summaries:
        relative = s["direct_median"] / baseline
        print(f"{s['language']:<10} {s['direct_median']:<12.1f} {relative:<10.2f}x {s['library']} {s['library_version']}")

    # Print Inverse results
    summaries.sort(key=lambda x: x["inverse_median"])
    print("\n" + "-" * 40)
    print("Inverse (geodesic inverse problem)")
    print("-" * 40)
    print(f"{'Language':<10} {'Median (ms)':<12} {'Relative':<10} {'Library'}")
    print("-" * 60)

    baseline = summaries[0]["inverse_median"]
    for s in summaries:
        relative = s["inverse_median"] / baseline
        print(f"{s['language']:<10} {s['inverse_median']:<12.1f} {relative:<10.2f}x {s['library']} {s['library_version']}")

    # Print version info
    print("\n" + "-" * 40)
    print("Version Information")
    print("-" * 40)
    for s in sorted(summaries, key=lambda x: x["language"]):
        print(f"{s['language']}: {s['version']}")

    print("\n" + "=" * 80)


def main():
    if len(sys.argv) < 2:
        results_dir = "results"
    else:
        results_dir = sys.argv[1]

    if not os.path.isdir(results_dir):
        print(f"Results directory '{results_dir}' not found")
        sys.exit(1)

    results = load_results(results_dir)
    analyze(results)


if __name__ == "__main__":
    main()
