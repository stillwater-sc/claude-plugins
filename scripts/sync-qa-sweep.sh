#!/usr/bin/env bash
# Copy the qa-sweep skill and reviewer agent into a repository's .claude/.
#
# A scheduled cloud session clones only the target repository and doesn't add
# marketplaces from its settings, so the plugin can't load there. The files are
# copied in as a plain project skill and agent instead. This repository stays
# the only place they are edited; each copy carries a header naming its source.
#
# Usage: scripts/sync-qa-sweep.sh [--check] <repo-dir>...
#   --check  change nothing; exit 1 if any copy differs from what a sync writes

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
plugin=plugins/qa-sweep

check=0
if [ "${1:-}" = "--check" ]; then
  check=1
  shift
fi
if [ $# -eq 0 ]; then
  echo "usage: $0 [--check] <repo-dir>..." >&2
  exit 2
fi

if [ -n "$(git -C "$root" status --porcelain -- "$plugin")" ]; then
  echo "error: $plugin has uncommitted changes; commit them first" >&2
  exit 2
fi
sha=$(git -C "$root" log -1 --format=%h -- "$plugin")

# Write <src> with a provenance comment after its YAML frontmatter.
render() {
  awk -v note="<!-- Generated from stillwater-sc/claude-plugins $1 at $sha by scripts/sync-qa-sweep.sh. Edit it there, not here. -->" '
    { print }
    /^---$/ && ++n == 2 { print ""; print note }
  ' "$root/$1"
}

status=0
for repo in "$@"; do
  for pair in \
    "$plugin/skills/qa-sweep/SKILL.md:.claude/skills/qa-sweep/SKILL.md" \
    "$plugin/agents/qa-reviewer.md:.claude/agents/qa-reviewer.md"; do
    src=${pair%%:*}
    dst=$repo/${pair#*:}
    if [ "$check" -eq 1 ]; then
      if ! render "$src" | cmp -s - "$dst"; then
        echo "out of date: $dst"
        status=1
      fi
    else
      mkdir -p "$(dirname "$dst")"
      render "$src" > "$dst"
      echo "wrote $dst"
    fi
  done
  if [ ! -f "$repo/.claude/qa-sweep.md" ]; then
    echo "note: $repo has no .claude/qa-sweep.md; see $plugin/README.md" >&2
  fi
done
exit $status
