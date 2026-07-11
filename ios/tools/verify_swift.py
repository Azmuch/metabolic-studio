#!/usr/bin/env python3
"""Structural verifier for the Metabolic iOS codebase (no Swift toolchain available).

Checks, per docs/SPEC.md §9:
  1. Balanced {} () [] per file (strings/comments stripped).
  2. No duplicate top-level type declarations across the codebase.
  3. Every SPEC contract symbol declared exactly once.
  4. No merge-conflict markers.
  5. MetabolicCore/Sources imports Foundation only (Linux-compatible).
  6. --strict: no TODO / FIXME / SPEC-GAP left.

Usage: python3 tools/verify_swift.py [--strict]   (run from ios/)
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STRICT = "--strict" in sys.argv

CONTRACT_SYMBOLS = [
    "BiologicalSex", "FitnessGoal", "ActivityLevel", "ExperienceLevel",
    "Equipment", "InjuryFlag", "FitnessProfile", "NutritionTargets",
    "NutritionEngine", "CalorieBurnCalculator", "PosePoint", "Joint", "Pose",
    "ExerciseKind", "MuscleGroup", "Exercise", "ExerciseLibrary", "DayFocus",
    "WorkoutItem", "WorkoutPlan", "SeededRandom", "WorkoutPlanGenerator",
    "MealType", "FoodItem", "FoodDatabase", "AnalyzedFoodItem",
    "MealPhotoAnalysis", "AdditiveRisk", "AdditiveTable", "ScannedProduct",
    "ScoreRating", "ScoreFactor", "ProductScore", "ProductScoringEngine",
    "StreakCalculator",
    # v2
    "ScheduleAnchor", "ScheduleRecommender", "ExerciseCategory",
    "MealPlanGenerator", "PlannedMeal", "PlannedMealItem", "MealPlanDay", "GroceryLine",
]

CORE_ALLOWED_IMPORTS = {"Foundation", "XCTest", "MetabolicCore"}

DECL_RE = re.compile(
    r"(?:^|\s)(?:@\w+(?:\([^)]*\))?\s+)*"
    r"(?:public\s+|internal\s+|private\s+|fileprivate\s+|final\s+|indirect\s+)*"
    r"(class|struct|enum|protocol|actor)\s+([A-Za-z_]\w*)"
)


def strip_code(text: str) -> str:
    """Remove comments and string literals, preserving newlines and delimiters."""
    out = []
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if ch == "/" and nxt == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif ch == "/" and nxt == "*":
            depth = 1
            i += 2
            while i < n and depth:
                if text[i] == "/" and i + 1 < n and text[i + 1] == "*":
                    depth += 1
                    i += 2
                elif text[i] == "*" and i + 1 < n and text[i + 1] == "/":
                    depth -= 1
                    i += 2
                else:
                    if text[i] == "\n":
                        out.append("\n")
                    i += 1
        elif ch == '"':
            if text[i : i + 3] == '"""':
                i += 3
                while i < n and text[i : i + 3] != '"""':
                    if text[i] == "\n":
                        out.append("\n")
                    i += 2 if text[i] == "\\" else 1
                i += 3
            else:
                i += 1
                while i < n and text[i] != '"':
                    if text[i] == "\\":
                        i += 2
                        continue
                    if text[i] == "\n":
                        break
                    i += 1
                i += 1
            out.append('""')
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def top_level_decls(stripped: str):
    """Yield (kind, name, line) for declarations at brace depth 0."""
    depth = 0
    for lineno, line in enumerate(stripped.split("\n"), 1):
        if depth == 0:
            m = DECL_RE.search(line)
            if m and line[: m.start(1)].count("}") == line[: m.start(1)].count("{"):
                yield m.group(1), m.group(2), lineno
        depth += line.count("{") - line.count("}")


def main() -> int:
    errors, warnings = [], []
    decls = {}  # name -> [(file, line)]

    files = sorted(ROOT.rglob("*.swift"))
    files = [f for f in files if ".build" not in f.parts and "DerivedData" not in f.parts]
    if not files:
        print("No Swift files found under", ROOT)
        return 1

    for f in files:
        rel = f.relative_to(ROOT)
        text = f.read_text(encoding="utf-8")

        for marker in ("<" * 7, "=" * 7, ">" * 7):
            for lineno, line in enumerate(text.split("\n"), 1):
                if line.startswith(marker):
                    errors.append(f"{rel}:{lineno}: merge-conflict marker")

        stripped = strip_code(text)
        for open_c, close_c in (("{", "}"), ("(", ")"), ("[", "]")):
            bal = stripped.count(open_c) - stripped.count(close_c)
            if bal:
                errors.append(f"{rel}: unbalanced '{open_c}{close_c}' (delta {bal:+d})")

        in_core_sources = "MetabolicCore" in f.parts and "Sources" in f.parts
        if in_core_sources:
            for lineno, line in enumerate(stripped.split("\n"), 1):
                m = re.match(r"\s*import\s+(\w+)", line)
                if m and m.group(1) not in CORE_ALLOWED_IMPORTS:
                    errors.append(
                        f"{rel}:{lineno}: MetabolicCore imports '{m.group(1)}' "
                        f"(Foundation only — must build on Linux)"
                    )

        is_test = "Tests" in f.parts
        for kind, name, lineno in top_level_decls(stripped):
            if not is_test:
                decls.setdefault(name, []).append((str(rel), lineno))

        for pat in ("TODO", "FIXME", "SPEC-GAP"):
            for lineno, line in enumerate(text.split("\n"), 1):
                if pat in line:
                    (errors if STRICT else warnings).append(f"{rel}:{lineno}: {pat}")

    for name, sites in sorted(decls.items()):
        if len(sites) > 1:
            locs = ", ".join(f"{p}:{l}" for p, l in sites)
            errors.append(f"duplicate top-level type '{name}': {locs}")

    for sym in CONTRACT_SYMBOLS:
        sites = decls.get(sym, [])
        if len(sites) == 0:
            errors.append(f"SPEC contract symbol '{sym}' not declared anywhere")
        core_sites = [s for s in sites if s[0].startswith("MetabolicCore/")]
        if sites and not core_sites:
            errors.append(f"SPEC contract symbol '{sym}' must live in MetabolicCore (found: {sites})")

    print(f"Scanned {len(files)} Swift files, {len(decls)} top-level types.")
    for w in warnings:
        print("WARN ", w)
    for e in errors:
        print("ERROR", e)
    print("FAIL" if errors else "OK")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
