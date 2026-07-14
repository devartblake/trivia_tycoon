"""One-shot F-docs bulk string rewrite. Safe to delete after wave F-docs."""
from __future__ import annotations

from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]

SKIP_DIRS = {
    "build",
    ".dart_tool",
    ".git",
    ".cxx",
    ".gradle",
    "ephemeral",
    "Pods",
    "node_modules",
    ".pub-cache",
}
# Preserve historical rename status tables (before/after).
SKIP_FILES = {
    "FLUTTER_RENAME_F1_F2_F3.md",
    "FLUTTER_RENAME_F4_F5.md",
    "_fdocs_bulk_rename.py",
}

TEXT_EXTS = {
    ".md",
    ".dart",
    ".json",
    ".yaml",
    ".yml",
    ".xml",
    ".txt",
    ".sh",
    ".ps1",
    ".py",
    ".html",
    ".rc",
    ".cmake",
    ".plist",
    ".xcconfig",
    ".gradle",
    ".kt",
    ".cpp",
    ".h",
    ".cc",
    ".swift",
    ".arb",
    ".properties",
    ".toml",
    ".ini",
    ".example",
    ".local",
    ".prod",
    ".staging",
}

TOP_LEVELS = {
    "docs",
    "scripts",
    "assets",
    "ops",
    ".github",
    "lib",
    "test",
    "web",
    "android",
    "ios",
    "macos",
    "windows",
    "linux",
    "protos",
}

REPLACEMENTS = [
    ("package:trivia_tycoon/", "package:synaptix/"),
    ("com.theoreticalmindstech.trivia_tycoon", "com.theoreticalmindstech.synaptix"),
    ("com.theoreticalmindstech.triviaTycoon", "com.theoreticalmindstech.synaptix"),
    ("com.synaptixplay.trivia_tycoon", "com.synaptixplay.synaptix"),
    ("Trivia Tycoon", "Synaptix"),
    ("TRIVIA TYCOON", "SYNAPTIX"),
    ("TriviaTycoon", "Synaptix"),
    ("trivia_tycoon_appLogo", "synaptix_appLogo_legacy"),
    ("trivia_tycoon_migration", "synaptix_migration"),
    ("trivia_tycoon_quiz", "synaptix_quiz"),
    ("trivia_tycoon_backend", "synaptix_backend"),
    ("TRIVIA_TYCOON_", "SYNAPTIX_"),
    ("import_github_issues_trivia_tycoon", "import_github_issues_synaptix"),
    ("Tycoon.Backend", "Synaptix.Backend"),
    ("tycoon.mobile", "synaptix.mobile"),
    ("tycoon.sidecar", "synaptix.sidecar"),
    ("--trivia-env=", "--synaptix-env="),
    ("[trivia_tycoon]", "[synaptix]"),
    ("cd trivia_tycoon", "cd synaptix"),
]


def transform(text: str) -> str:
    for old, new in REPLACEMENTS:
        text = text.replace(old, new)

    # Remaining bare package/folder identifiers, but do not rewrite the live
    # GitHub remote slug until the remote is renamed on GitHub.
    def _bare(match: re.Match[str]) -> str:
        return "synaptix"

    text = re.sub(r"(?<!github\.com/devartblake/)(?<!/)trivia_tycoon\b", _bare, text)

    # If the regex still rewrote a remote path, restore it.
    text = text.replace(
        "github.com/devartblake/synaptix", "github.com/devartblake/trivia_tycoon"
    )
    text = text.replace("devartblake/synaptix", "devartblake/trivia_tycoon")
    return text


def main() -> None:
    changed: list[str] = []
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.name in SKIP_FILES:
            continue

        rel = path.relative_to(root)
        top = rel.parts[0] if rel.parts else ""
        if top not in TOP_LEVELS and path.parent != root:
            continue

        if path.suffix.lower() not in TEXT_EXTS and path.parent != root:
            # allow extensionless under docs
            if path.suffix != "":
                continue

        try:
            raw = path.read_bytes()
        except OSError:
            continue
        if b"\0" in raw[:2048]:
            continue
        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue

        lower = text.lower()
        if "trivia" not in lower and "tycoon" not in lower:
            continue

        new = transform(text)
        if new != text:
            path.write_text(new, encoding="utf-8", newline="\n")
            changed.append(str(rel).replace("\\", "/"))

    print(f"content files updated: {len(changed)}")
    for f in changed[:80]:
        print(f"  {f}")
    if len(changed) > 80:
        print(f"  ... +{len(changed) - 80} more")


if __name__ == "__main__":
    main()
