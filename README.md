# claude-plugins

Claude Code plugins shared across the Stillwater Supercomputing repositories,
published as the `stillwater-plugins` marketplace.

| Plugin | What it does |
|---|---|
| [`qa-sweep`](plugins/qa-sweep/README.md) | Daily QA sweep of a C++ repository: build and test, review the commits since the last sweep, a rotating deep pass with sanitizers, and one GitHub issue with the findings. |

## Using the marketplace

```bash
claude plugin marketplace add stillwater-sc/claude-plugins
claude plugin install <plugin>@stillwater-plugins
```

A scheduled cloud task can't load plugins this way, because a cloud session
doesn't add marketplaces from repository settings. Plugins meant for scheduled
runs are copied into each repository by a script under `scripts/`; see the
plugin's README.

## Layout

```
.claude-plugin/marketplace.json   the marketplace catalog
plugins/<name>/                   one directory per plugin
  .claude-plugin/plugin.json
  skills/<skill>/SKILL.md
  agents/<agent>.md
scripts/                          sync scripts for repositories that run a plugin on a schedule
```

Check a change with `claude plugin validate . --strict` and
`claude plugin validate plugins/<name> --strict`.
