#!/usr/bin/env python3
"""
Publish issues from issues.md to GitHub with appropriate labels.
"""

import re
import subprocess
import sys
from pathlib import Path

# Configuration
REPO = "SoroGame-Plearn/PLEarn-Contract"
ISSUES_FILE = Path(__file__).parent.parent / "issues.md"

# Define labels with descriptions and colors
LABELS = {
    "infra": ("Infrastructure and DevOps", "0088cc"),
    "docs": ("Documentation", "d4c5f9"),
    "challenge": ("Challenge Implementation", "006b75"),
    "test": ("Testing and QA", "ffd700"),
    "phase-1": ("Phase 1: Foundation", "e2a881"),
    "phase-2": ("Phase 2: Beginner", "f9d5e5"),
    "phase-3": ("Phase 3: Intermediate", "c2e0c6"),
    "phase-4": ("Phase 4: Advanced", "b3e5fc"),
    "phase-5": ("Phase 5: Community", "fff3cd"),
    "difficulty-low": ("Low Complexity", "90ee90"),
    "difficulty-medium": ("Medium Complexity", "ffa500"),
    "difficulty-high": ("High Complexity", "ff6b6b"),
    "good-first-issue": ("Good First Issue", "7057ff"),
    "help-wanted": ("Help Wanted", "008672"),
}

def run_command(cmd):
    """Run a shell command and return stdout."""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"✗ Command failed: {cmd}")
        print(f"  Error: {e.stderr}")
        return None

def create_labels():
    """Create labels in the GitHub repository."""
    print("Creating labels...")
    for label_name, (description, color) in LABELS.items():
        # Create label (it's okay if it already exists)
        cmd_parts = ['gh', 'label', 'create', label_name, '-R', REPO, 
                     '--description', description, '--color', color]
        
        try:
            subprocess.run(cmd_parts, capture_output=True, text=True, check=True)
            print(f"✓ Created label: {label_name}")
        except subprocess.CalledProcessError as e:
            if 'already exists' in e.stderr:
                print(f"→ Label already exists: {label_name}")
            else:
                print(f"! Warning: {label_name} - {e.stderr.strip()}")

def parse_issues():
    """Parse issues from issues.md file."""
    with open(ISSUES_FILE, 'r') as f:
        content = f.read()
    
    # Split by issue headers: ## [Type] Title
    issue_pattern = r'## \[([^\]]+)\]\s+(.+?)\n\n(.*?)(?=\n## \[|\Z)'
    matches = re.finditer(issue_pattern, content, re.DOTALL)
    
    issues = []
    for match in matches:
        issue_type = match.group(1)
        title = match.group(2)
        body = match.group(3).strip()
        
        issues.append({
            'type': issue_type,
            'title': title,
            'body': body,
        })
    
    return issues

def determine_labels(issue_type, body):
    """Determine labels for an issue based on type and content."""
    labels = set()
    
    # Type-based labels
    type_map = {
        'Infra': 'infra',
        'Docs': 'docs',
        'Challenge': 'challenge',
        'Scripts': 'infra',
        'CI/CD': 'infra',
    }
    
    if issue_type in type_map:
        labels.add(type_map[issue_type])
    
    # Phase-based labels and difficulty
    if 'Phase 1' in body:
        labels.add('phase-1')
        labels.add('difficulty-low')
        labels.add('good-first-issue')
    elif 'Phase 2' in body:
        labels.add('phase-2')
        labels.add('difficulty-low')
        labels.add('good-first-issue')
    elif 'Phase 3' in body:
        labels.add('phase-3')
        labels.add('difficulty-medium')
        labels.add('help-wanted')
    elif 'Phase 4' in body:
        labels.add('phase-4')
        labels.add('difficulty-high')
        labels.add('help-wanted')
    elif 'Phase 5' in body:
        labels.add('phase-5')
        labels.add('difficulty-medium')
    
    # Test-related issues
    if 'test' in body.lower():
        labels.add('test')
    
    return list(labels)

def create_issue(title, body, labels):
    """Create an issue on GitHub."""
    # Build labels argument
    labels_arg = ' '.join([f'-l {label}' for label in labels])
    
    # Build command with stdin for body to avoid escaping issues
    cmd_parts = ['gh', 'issue', 'create', '-R', REPO, '--title', title, '--body', '-']
    if labels_arg:
        cmd_parts.extend(labels_arg.split())
    
    try:
        result = subprocess.run(
            cmd_parts,
            input=body,
            capture_output=True,
            text=True,
            check=True
        )
        return True
    except subprocess.CalledProcessError as e:
        print(f"  Error: {e.stderr}")
        return False

def main():
    """Main entry point."""
    print(f"Publishing issues to {REPO}...\n")
    
    # Check if gh CLI is available
    if not run_command("which gh"):
        print("✗ GitHub CLI (gh) not found. Please install it: https://cli.github.com")
        sys.exit(1)
    
    # Verify authentication
    if not run_command("gh auth status"):
        print("✗ Not authenticated with GitHub. Run: gh auth login")
        sys.exit(1)
    
    # Create labels
    print()
    create_labels()
    
    # Parse issues
    print("\nParsing issues.md...")
    issues = parse_issues()
    print(f"Found {len(issues)} issues\n")
    
    if not issues:
        print("No issues found in issues.md")
        sys.exit(1)
    
    # Create issues
    print("Publishing issues...")
    created = 0
    failed = 0
    
    for i, issue in enumerate(issues, 1):
        labels = determine_labels(issue['type'], issue['body'])
        
        if create_issue(issue['title'], issue['body'], labels):
            print(f"✓ ({i:2d}/30) {issue['title']}")
            created += 1
        else:
            print(f"✗ ({i:2d}/30) {issue['title']}")
            failed += 1
    
    # Summary
    print("\n" + "="*50)
    print(f"Total issues processed: {len(issues)}")
    print(f"Successfully created: {created}")
    if failed > 0:
        print(f"Failed: {failed}")
    print("="*50)
    print(f"\nView issues at: https://github.com/{REPO}/issues")

if __name__ == '__main__':
    main()
