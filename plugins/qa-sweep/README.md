# qa-sweep

A daily QA sweep for a C++ repository, meant to run as a scheduled Claude Code
task. Each run:

1. builds the repository and runs its tests;
2. reviews the commits since the last sweep;
3. takes a deep pass over one area of the code, rotating by day of the year,
   with the area's tests run under the sanitizers;
4. files the findings as one GitHub issue, `QA sweep YYYY-MM-DD: <area>`,
   labelled `qa-sweep`.

It reports functional bugs, regression-test gaps and performance problems.
Every finding needs a `file:line` and is marked confirmed or unconfirmed. It
never edits code, pushes, opens PRs or comments on existing issues; the
sweep issue (and the `qa-sweep` label, the first time) is its only write.

The plugin has two parts:

- `skills/qa-sweep/SKILL.md`: the procedure.
- `agents/qa-reviewer.md`: a reviewer with no file-writing tools, which the
  skill hands each review to.

Everything that differs between repositories lives in that repository's
`.claude/qa-sweep.md`.

## Adopting it in a repository

A scheduled task runs in a cloud session that clones only the target
repository, and a cloud session doesn't add the marketplaces a repository's
settings declare
([docs](https://code.claude.com/docs/en/plugins/loading#plugins-shared-through-a-repository)).
So the scheduled run can't load this plugin. Instead, the skill and agent are
copied into the repository as a plain project skill and agent, which cloud
sessions do load:

```bash
# from this repository
scripts/sync-qa-sweep.sh ../<repo>          # writes .claude/skills/qa-sweep/SKILL.md
                                            # and .claude/agents/qa-reviewer.md
scripts/sync-qa-sweep.sh --check ../<repo>  # exit 1 if the copies are stale
```

The copies carry a header naming the commit they came from. Edit them here and
sync again; don't edit them in the target repository.

Then add `.claude/qa-sweep.md` to the repository (format below) and open one
PR with the three files.

### Scheduling

Create the scheduled task with `/schedule`, or at claude.ai/code:

- **Repository:** the repository.
- **Prompt:** `/qa-sweep`
- **Schedule:** for example `CRON_TZ=America/New_York 7 6 * * *` (a plain cron
  is read as UTC).
- **Environment:** `BASH_DEFAULT_TIMEOUT_MS=1800000`, so long builds aren't cut
  off at the 2-minute command limit.

Use "Run now" once before the first scheduled run, to check that `gh` is
logged in inside the cloud session and how long a sweep takes.

### Running it locally

To run a sweep by hand in a repository that has a config, add this
marketplace and install the plugin:

```bash
claude plugin marketplace add stillwater-sc/claude-plugins
claude plugin install qa-sweep@stillwater-plugins
```

The plugin's skill is then `/qa-sweep:qa-sweep`. A repository with the synced
copies also has `/qa-sweep`, which is the same procedure.

## The config file: `.claude/qa-sweep.md`

A Markdown file with these `##` sections. The skill reads them by heading.

| Section | What it holds |
|---|---|
| `Repository` | `owner/name`, used in every `gh` command. |
| `Project` | One paragraph on what the code is, and which files state its rules (usually `CLAUDE.md`). |
| `Build and test` | The configure, build and test commands, the build directories, and the `-j` limit. |
| `Docs-only paths` | Paths whose commits the commit review skips. |
| `Areas` | A numbered table, from 0: area, headers or sources, and the test selection. The sweep rotates through them by day of the year. |
| `Sanitizers` | The configure, build and run commands for the sanitizer pass, with `<selection>` where the area's test selection goes. Or `none`. |
| `Review focus` | What counts as a defect in this codebase, beyond the reviewer's general checklist. |

Keep the commands to `cmake`, `ctest`, `date`, `nproc`, `mkdir` and the read-only `git` subcommands,
which the skill pre-approves. Another command still runs in auto mode, but
goes through its classifier, and in a mode that asks for permission it stalls
an unattended run.

See [stillwater-sc/mtl5's config](https://github.com/stillwater-sc/mtl5/blob/main/.claude/qa-sweep.md)
for a complete example.
