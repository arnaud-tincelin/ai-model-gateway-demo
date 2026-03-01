#!/usr/bin/env python3
"""
Script to create GitHub issues from markdown files in the issues/ folder.

Each markdown file should have YAML frontmatter with the following format:
---
title: Issue Title
labels: label1, label2
assignees: user1, user2
---

Issue body content here...
"""

import os
import sys
import re
from pathlib import Path
from typing import Dict, Optional, List
import argparse

try:
    from github import Github, GithubException
except ImportError:
    print("Error: PyGithub is not installed. Please install it with: pip install PyGithub")
    sys.exit(1)


def parse_frontmatter(content: str) -> tuple[Dict[str, str], str]:
    """
    Parse YAML frontmatter from markdown content.
    
    Returns:
        Tuple of (frontmatter_dict, body_content)
    """
    frontmatter_pattern = r'^---\s*\n(.*?)\n---\s*\n(.*)'
    match = re.match(frontmatter_pattern, content, re.DOTALL)
    
    if not match:
        return {}, content
    
    frontmatter_text = match.group(1)
    body = match.group(2).strip()
    
    # Parse simple YAML frontmatter
    frontmatter = {}
    for line in frontmatter_text.split('\n'):
        if ':' in line:
            key, value = line.split(':', 1)
            frontmatter[key.strip()] = value.strip()
    
    return frontmatter, body


def parse_list_field(value: str) -> List[str]:
    """Parse a comma-separated list field, filtering out empty values."""
    if not value:
        return []
    return [item.strip() for item in value.split(',') if item.strip()]


def create_issue_from_file(github_client: Github, repo_name: str, filepath: Path, dry_run: bool = False) -> Optional[str]:
    """
    Create a GitHub issue from a markdown file.
    
    Args:
        github_client: Authenticated GitHub client
        repo_name: Repository name in format 'owner/repo'
        filepath: Path to the markdown file
        dry_run: If True, only print what would be created without actually creating
        
    Returns:
        Issue URL if created, None otherwise
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        frontmatter, body = parse_frontmatter(content)
        
        # Title is required
        title = frontmatter.get('title', '')
        if not title:
            print(f"Warning: Skipping {filepath.name} - no title specified")
            return None
        
        # Parse optional fields
        labels = parse_list_field(frontmatter.get('labels', ''))
        assignees = parse_list_field(frontmatter.get('assignees', ''))
        
        if dry_run:
            print(f"\n[DRY RUN] Would create issue from {filepath.name}:")
            print(f"  Title: {title}")
            print(f"  Labels: {labels if labels else 'None'}")
            print(f"  Assignees: {assignees if assignees else 'None'}")
            print(f"  Body: {body[:100]}..." if len(body) > 100 else f"  Body: {body}")
            return "dry-run"  # Return a non-None value to count this as successful
        
        # Get repository
        repo = github_client.get_repo(repo_name)
        
        # Create the issue
        issue = repo.create_issue(
            title=title,
            body=body,
            labels=labels if labels else None,
            assignees=assignees if assignees else None
        )
        
        print(f"✓ Created issue #{issue.number}: {title}")
        print(f"  URL: {issue.html_url}")
        return issue.html_url
        
    except FileNotFoundError:
        print(f"Error: File not found: {filepath}")
        return None
    except GithubException as e:
        print(f"Error creating issue from {filepath.name}: {e}")
        return None
    except Exception as e:
        print(f"Unexpected error processing {filepath.name}: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(
        description='Create GitHub issues from markdown files in the issues/ folder'
    )
    parser.add_argument(
        'files',
        nargs='*',
        help='Specific issue files to process (default: all .md files in issues/)'
    )
    parser.add_argument(
        '--repo',
        help='Repository in format owner/repo (default: auto-detect from git)',
        default=None
    )
    parser.add_argument(
        '--token',
        help='GitHub personal access token (default: use GITHUB_TOKEN env var)',
        default=None
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be created without actually creating issues'
    )
    
    args = parser.parse_args()
    
    # Get GitHub token (not required for dry-run)
    token = args.token or os.environ.get('GITHUB_TOKEN')
    if not token and not args.dry_run:
        print("Error: GitHub token not provided. Set GITHUB_TOKEN environment variable or use --token")
        sys.exit(1)
    
    # Get repository name
    repo_name = args.repo
    if not repo_name:
        # Try to detect from git remote
        try:
            import subprocess
            result = subprocess.run(
                ['git', 'config', '--get', 'remote.origin.url'],
                capture_output=True,
                text=True,
                check=True
            )
            remote_url = result.stdout.strip()
            # Parse owner/repo from URL
            match = re.search(r'github\.com[:/](.+/.+?)(\.git)?$', remote_url)
            if match:
                repo_name = match.group(1).replace('.git', '')
            else:
                print("Error: Could not parse repository name from git remote")
                sys.exit(1)
        except Exception as e:
            print(f"Error: Could not detect repository name from git. Use --repo option: {e}")
            sys.exit(1)
    
    print(f"Repository: {repo_name}")
    
    # Initialize GitHub client (skip for dry-run)
    github_client = None
    if not args.dry_run:
        try:
            github_client = Github(token)
            # Test authentication
            github_client.get_user().login
        except Exception as e:
            print(f"Error: Failed to authenticate with GitHub: {e}")
            sys.exit(1)
    
    # Determine which files to process
    if args.files:
        issue_files = [Path(f) for f in args.files]
    else:
        # Process all .md files in issues/ folder (excluding README.md)
        issues_dir = Path('issues')
        if not issues_dir.exists():
            print(f"Error: issues/ directory not found")
            sys.exit(1)
        issue_files = [f for f in issues_dir.glob('*.md') if f.name.lower() != 'readme.md']
    
    if not issue_files:
        print("No issue files found to process")
        sys.exit(0)
    
    print(f"Processing {len(issue_files)} issue file(s)...\n")
    
    # Create issues
    created_count = 0
    for filepath in issue_files:
        result = create_issue_from_file(github_client, repo_name, filepath, dry_run=args.dry_run)
        if result:
            created_count += 1
    
    print(f"\n{'[DRY RUN] ' if args.dry_run else ''}Summary: {created_count} issue(s) {'would be ' if args.dry_run else ''}created")


if __name__ == '__main__':
    main()
