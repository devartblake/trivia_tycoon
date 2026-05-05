#!/usr/bin/env python3
"""
Import GitHub issues for the trivia_tycoon repository.

Default target repo:
    devartblake/trivia_tycoon

Default issue package:
    ops/issues/skill_tree_navigation_github_issues.json

Expected JSON shape:
    {
      "repository": "devartblake/trivia_tycoon",
      "labels": ["skill-tree", "frontend"],
      "milestones": [{"title": "...", "description": "..."}],
      "issues": [
        {
          "id": "STN-001",
          "title": "...",
          "body": "...",
          "labels": ["skill-tree"],
          "milestone": "Skill Tree Navigation Stabilization",
          "assignees": [],
          "priority": "P1",
          "estimate": "S",
          "type": "bug",
          "files": ["lib/..."],
          "acceptance_criteria": ["..."],
          "dependencies": ["STN-001"]
        }
      ]
    }

Usage from repo root:
    python ops/scripts/import_github_issues.py --dry-run

Live import:
    GITHUB_TOKEN=ghp_xxx python ops/scripts/import_github_issues.py --apply

Optional:
    python ops/scripts/import_github_issues.py \
      --repo devartblake/trivia_tycoon \
      --json ops/issues/skill_tree_navigation_github_issues.json \
      --apply
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence
from urllib.parse import quote

import requests


DEFAULT_REPO = "devartblake/trivia_tycoon"
DEFAULT_JSON_FILE = "ops/issues/skill_tree_navigation_github_issues.json"
API_VERSION = "2022-11-28"
DEFAULT_LABEL_COLOR = "0e8a16"


@dataclass(frozen=True)
class GitHubConfig:
    """Runtime configuration for GitHub API calls."""

    repo: str
    token: str
    api_version: str = API_VERSION

    @property
    def base_url(self) -> str:
        return f"https://api.github.com/repos/{self.repo}"

    @property
    def headers(self) -> Dict[str, str]:
        return {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {self.token}",
            "X-GitHub-Api-Version": self.api_version,
        }


class GitHubIssueImporter:
    """Small GitHub Issues importer for repo-local JSON issue packages."""

    def __init__(self, config: GitHubConfig, dry_run: bool = True, skip_existing: bool = True) -> None:
        self.config = config
        self.dry_run = dry_run
        self.skip_existing = skip_existing

    def _request(
        self,
        method: str,
        url: str,
        *,
        payload: Optional[dict] = None,
        params: Optional[dict] = None,
        expected_statuses: Sequence[int] = (200, 201),
    ) -> Any:
        """Run a GitHub API request and return decoded JSON where available."""
        if self.dry_run and method.upper() in {"POST", "PATCH", "PUT", "DELETE"}:
            print(f"[dry-run] {method.upper()} {url}")
            if payload:
                print(json.dumps(payload, indent=2))
            return {}

        response = requests.request(
            method=method.upper(),
            url=url,
            headers=self.config.headers,
            json=payload,
            params=params,
            timeout=30,
        )

        if response.status_code not in expected_statuses:
            print(f"\nGitHub API error: {method.upper()} {url}", file=sys.stderr)
            print(f"Status: {response.status_code}", file=sys.stderr)
            print(response.text, file=sys.stderr)
            response.raise_for_status()

        if not response.text:
            return {}

        return response.json()

    def _get_paginated(self, url: str, *, params: Optional[dict] = None) -> List[dict]:
        """Read all pages from a GitHub list endpoint."""
        items: List[dict] = []
        page = 1

        while True:
            merged_params = {"per_page": 100, "page": page}
            if params:
                merged_params.update(params)

            batch = self._request("GET", url, params=merged_params)
            if not batch:
                break

            items.extend(batch)
            page += 1

        return items

    def list_repo_labels(self) -> Dict[str, dict]:
        """Return existing repository labels keyed by label name."""
        labels = self._get_paginated(f"{self.config.base_url}/labels")
        return {label["name"]: label for label in labels}

    def create_label_if_missing(self, name: str, existing: Dict[str, dict]) -> None:
        """Create a GitHub label if it does not exist."""
        if not name or name in existing:
            return

        payload = {
            "name": name,
            "color": DEFAULT_LABEL_COLOR,
            "description": f"Imported label: {name}"[:100],
        }

        created = self._request("POST", f"{self.config.base_url}/labels", payload=payload)
        existing[name] = created or {"name": name}
        print(f"Label ready: {name}")

    def list_repo_milestones(self) -> Dict[str, dict]:
        """Return existing repository milestones keyed by title."""
        milestones = self._get_paginated(
            f"{self.config.base_url}/milestones",
            params={"state": "all"},
        )
        return {milestone["title"]: milestone for milestone in milestones}

    def create_milestone_if_missing(
        self,
        title: str,
        existing: Dict[str, dict],
        *,
        description: Optional[str] = None,
    ) -> dict:
        """Create a GitHub milestone if it does not exist."""
        if not title:
            return {}

        if title in existing:
            return existing[title]

        payload: Dict[str, Any] = {"title": title}
        if description:
            payload["description"] = description

        created = self._request("POST", f"{self.config.base_url}/milestones", payload=payload)
        existing[title] = created or {"title": title, "number": None}
        print(f"Milestone ready: {title}")
        return existing[title]

    def find_existing_issue_by_title(self, title: str) -> Optional[dict]:
        """Find an existing open/closed issue by exact title using GitHub search."""
        # GitHub issue search is faster and avoids creating duplicates when importer is rerun.
        encoded_title = quote(f'"{title}"')
        encoded_repo = quote(self.config.repo)
        url = f"https://api.github.com/search/issues?q={encoded_title}+repo:{encoded_repo}+in:title+type:issue"

        result = self._request("GET", url)
        for item in result.get("items", []):
            if item.get("title") == title:
                return item

        return None

    def create_issue(self, issue: dict, milestone_number: Optional[int]) -> Optional[str]:
        """Create one GitHub issue and return its URL."""
        title = issue.get("title")
        if not title:
            raise ValueError(f"Issue is missing title: {issue}")

        if self.skip_existing:
            existing = self.find_existing_issue_by_title(title)
            if existing:
                url = existing.get("html_url")
                print(f"Skipped existing: {title} -> {url}")
                return None

        payload: Dict[str, Any] = {
            "title": title,
            "body": build_issue_body(issue),
            "labels": normalize_labels(issue.get("labels", [])),
        }

        if milestone_number is not None:
            payload["milestone"] = milestone_number

        # The uploaded package currently uses empty assignees, but this supports real GitHub usernames.
        assignees = normalize_string_list(issue.get("assignees", []))
        if assignees:
            payload["assignees"] = assignees

        created = self._request("POST", f"{self.config.base_url}/issues", payload=payload)
        url = created.get("html_url") if created else None

        if url:
            print(f"Created: {url}")
        else:
            print(f"[dry-run] Prepared issue: {title}")

        return url

    def import_issues(self, package: dict) -> List[str]:
        """Import all issues from an issue package."""
        repo_from_package = package.get("repository")
        if repo_from_package and repo_from_package != self.config.repo:
            print(
                f"Warning: JSON package repository is '{repo_from_package}', "
                f"but importer target is '{self.config.repo}'.",
                file=sys.stderr,
            )

        issues = package.get("issues", [])
        if not isinstance(issues, list):
            raise ValueError("JSON package must contain an 'issues' array.")

        existing_labels = self.list_repo_labels()
        existing_milestones = self.list_repo_milestones()

        # Create top-level package labels plus labels used by individual issues.
        all_labels = set(normalize_string_list(package.get("labels", [])))
        for issue in issues:
            all_labels.update(normalize_labels(issue.get("labels", [])))
            if issue.get("priority"):
                all_labels.add(str(issue["priority"]).lower())
            if issue.get("type"):
                all_labels.add(str(issue["type"]).lower())

        for label in sorted(all_labels):
            self.create_label_if_missing(label, existing_labels)

        # Create top-level milestones and issue-referenced milestones.
        milestone_descriptions = read_milestone_descriptions(package.get("milestones", []))
        all_milestone_titles = set(milestone_descriptions.keys())
        for issue in issues:
            if issue.get("milestone"):
                all_milestone_titles.add(str(issue["milestone"]))

        for milestone_title in sorted(all_milestone_titles):
            self.create_milestone_if_missing(
                milestone_title,
                existing_milestones,
                description=milestone_descriptions.get(milestone_title),
            )

        # Refresh milestones after possible creation so numbers are available.
        if not self.dry_run:
            existing_milestones = self.list_repo_milestones()

        created_urls: List[str] = []

        for issue in issues:
            milestone_number = None
            milestone_title = issue.get("milestone")
            if milestone_title and milestone_title in existing_milestones:
                milestone_number = existing_milestones[milestone_title].get("number")

            url = self.create_issue(issue, milestone_number)
            if url:
                created_urls.append(url)

        return created_urls


def normalize_string_list(value: Any) -> List[str]:
    """Normalize strings/lists into a clean list of strings."""
    if value is None:
        return []

    if isinstance(value, str):
        return [value] if value.strip() else []

    if not isinstance(value, list):
        return []

    return [str(item).strip() for item in value if str(item).strip()]


def normalize_labels(value: Any) -> List[str]:
    """Normalize labels into GitHub-compatible names without duplicates."""
    seen = set()
    labels: List[str] = []

    for label in normalize_string_list(value):
        if label not in seen:
            seen.add(label)
            labels.append(label)

    return labels


def read_milestone_descriptions(value: Any) -> Dict[str, str]:
    """Read milestone title/description pairs from package metadata."""
    descriptions: Dict[str, str] = {}

    if not isinstance(value, list):
        return descriptions

    for item in value:
        if isinstance(item, str):
            descriptions[item] = ""
            continue

        if isinstance(item, dict) and item.get("title"):
            descriptions[str(item["title"])] = str(item.get("description", ""))

    return descriptions


def build_issue_body(issue: dict) -> str:
    """Build a GitHub Markdown issue body from the richer JSON schema."""
    body_parts: List[str] = []

    issue_id = issue.get("id")
    issue_type = issue.get("type")
    priority = issue.get("priority")
    estimate = issue.get("estimate")
    dependencies = normalize_string_list(issue.get("dependencies", []))
    files = normalize_string_list(issue.get("files", []))
    acceptance = normalize_string_list(issue.get("acceptance_criteria", []))

    if issue_id or issue_type or priority or estimate:
        meta_lines = []
        if issue_id:
            meta_lines.append(f"- **Issue ID:** `{issue_id}`")
        if issue_type:
            meta_lines.append(f"- **Type:** `{issue_type}`")
        if priority:
            meta_lines.append(f"- **Priority:** `{priority}`")
        if estimate:
            meta_lines.append(f"- **Estimate:** `{estimate}`")

        body_parts.append("## Metadata\n" + "\n".join(meta_lines))

    body = str(issue.get("body", "")).strip()
    if body:
        body_parts.append("## Summary\n" + body)

    if files:
        body_parts.append(
            "## Target Files\n"
            + "\n".join(f"- `{file_path}`" for file_path in files)
        )

    if acceptance:
        body_parts.append(
            "## Acceptance Criteria\n"
            + "\n".join(f"- [ ] {item}" for item in acceptance)
        )

    if dependencies:
        body_parts.append(
            "## Dependencies\n"
            + "\n".join(f"- `{dependency}`" for dependency in dependencies)
        )

    body_parts.append(
        "## Import Notes\n"
        "- Imported from `ops/issues/skill_tree_navigation_github_issues.json`.\n"
        "- Confirm implementation details against the current `trivia_tycoon` codebase before starting work."
    )

    return "\n\n".join(body_parts).strip() + "\n"


def resolve_json_path(json_arg: str) -> Path:
    """Resolve issue JSON path from current working directory."""
    path = Path(json_arg)
    if path.is_absolute():
        return path

    return Path.cwd() / path


def load_issue_package(json_path: Path) -> dict:
    """Load and validate an issue JSON package."""
    if not json_path.exists():
        raise FileNotFoundError(f"Issue JSON file not found: {json_path}")

    with json_path.open("r", encoding="utf-8") as file:
        package = json.load(file)

    if not isinstance(package, dict):
        raise ValueError("Issue JSON root must be an object.")

    if "issues" not in package:
        raise ValueError("Issue JSON must contain an 'issues' key.")

    return package


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    """Parse CLI arguments."""
    parser = argparse.ArgumentParser(
        description="Import trivia_tycoon GitHub issues from a repo-local JSON package."
    )
    parser.add_argument(
        "--repo",
        default=os.getenv("GITHUB_REPOSITORY", DEFAULT_REPO),
        help=f"GitHub repository in owner/name format. Default: {DEFAULT_REPO}",
    )
    parser.add_argument(
        "--json",
        default=DEFAULT_JSON_FILE,
        help=f"Path to issue JSON package. Default: {DEFAULT_JSON_FILE}",
    )
    parser.add_argument(
        "--token-env",
        default="GITHUB_TOKEN",
        help="Environment variable containing a GitHub token. Default: GITHUB_TOKEN",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually create labels, milestones, and issues. Without this flag, dry-run mode is used.",
    )
    parser.add_argument(
        "--no-skip-existing",
        action="store_true",
        help="Do not check for existing issue titles before creating issues.",
    )

    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> int:
    """CLI entry point."""
    args = parse_args(argv)
    dry_run = not args.apply

    token = os.getenv(args.token_env)
    if not token and not dry_run:
        print(
            f"Missing required environment variable: {args.token_env}\n"
            f"Example: {args.token_env}=ghp_xxx python ops/scripts/import_github_issues.py --apply",
            file=sys.stderr,
        )
        return 2

    # Dry-run still needs a token for GitHub reads unless you already know labels/milestones.
    # Using an empty token lets payload generation run until a live GitHub read is attempted.
    if not token:
        token = "DRY_RUN_TOKEN_NOT_USED_FOR_WRITES"

    json_path = resolve_json_path(args.json)
    package = load_issue_package(json_path)

    importer = GitHubIssueImporter(
        config=GitHubConfig(repo=args.repo, token=token),
        dry_run=dry_run,
        skip_existing=not args.no_skip_existing,
    )

    print(f"Repository: {args.repo}")
    print(f"Issue JSON: {json_path}")
    print(f"Mode: {'apply' if args.apply else 'dry-run'}")
    print()

    created_urls = importer.import_issues(package)

    print("\nDone.")
    if dry_run:
        print("Dry-run completed. Re-run with --apply to create issues.")
    else:
        print(f"Created {len(created_urls)} new issue(s).")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
