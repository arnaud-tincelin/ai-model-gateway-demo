# Issues Folder

This folder contains issue templates in Markdown format with YAML frontmatter.

## Format

Each issue file should follow this format:

```markdown
---
title: Issue Title Here
labels: label1, label2
assignees: username1, username2
---

Issue body content here in Markdown format.
```

## Fields

- `title`: (Required) The title of the GitHub issue
- `labels`: (Optional) Comma-separated list of labels to apply
- `assignees`: (Optional) Comma-separated list of GitHub usernames to assign

## Usage

Run the script to create GitHub issues from all `.md` files in this folder:

```bash
python scripts/create_issues.py
```

Or specify a specific file:

```bash
python scripts/create_issues.py issues/my-issue.md
```
