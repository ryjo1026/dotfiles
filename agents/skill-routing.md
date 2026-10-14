# Skill routing

Skills follow the [Agent Skills](https://agentskills.io) format (`<name>/SKILL.md`, lowercase-hyphen name matching the dir). Everything merges into `~/.agents/skills/`, which most agents (Codex, Cursor, Gemini CLI, OpenCode, Amp) read natively; `run_after_agent-skills.sh` fans the merged dir into agents that don't (Claude Code) and prunes dangling links.

## Creating a skill: pick the layer by audience first

Skills are laid out as `<name>/SKILL.md`, and live in one of five places:

| Audience | Where | Notes |
| --- | --- | --- |
| **This repo's own mechanics** | `skills/<name>/` **here** | dotfiles/chezmoi workflows only; highest precedence |
| Public (anyone) | [`ryjo1026/skills`](https://github.com/ryjo1026/skills) | all machines; nothing work-related or private |
| Private (only Ryan) | `ryjo1026/skills-private` on personal machines, `ryanjohnston-abridge/skills-private` on work machines | cloned to `~/.agents/sources/private`; work-only skills go in the work one |
| Team | `abridgeai/ryan-skills` | work machines only |
| Experiment / trial | real dir in `~/.agents/skills/<name>/` | unmanaged; promote to a repo if it sticks |

Default to **private** unless Ryan names another layer. Suggest team, once and before writing, when the skill would help other engineers — shared tooling, team conventions, internal services. Never default to public: moving later is cheap, but a work detail committed to a public repo is not undoable.

Commit and push private-repo skills to `main` without asking — new skills and edits alike. Every other layer follows the normal commit and push gates.

### Repo-local skills: `skills/` in this repo

A skill belongs here when **its subject is this repo** — chezmoi mechanics, the template layout, the shell-module convention, the Brewfile. `auditing-brewfile` is the worked example: it is about `dot_Brewfile.tmpl` and this repo's profile branches, so it is worthless anywhere else and would rot if it lived in a shared repo away from the files it describes.

The test is the *subject*, not the audience. A generally useful skill that happens to have been written here still goes to a source repo; only skills that describe this repo's own machinery stay.

- `skills/**` is in `.chezmoiignore`, so the dir never deploys to `$HOME`.
- Bundled resources follow the [Agent Skills](https://agentskills.io) layout — `scripts/` for executables, `references/` for docs, `assets/` for templates. A repo-local skill's script is a **plain file, never a `*.tmpl`**: `skills/` is not deployed, so nothing renders it. Locate the repo from the script's own path (`cd -P "$(dirname "${BASH_SOURCE[0]}")"` resolves the `~/.agents/skills` symlink) rather than hard-coding one.
- `run_after_agent-skills.sh` links these **straight out of the chezmoi source dir** and lists them first in `SOURCE_ROOTS`. Two consequences: editing a repo-local skill is **live immediately, with no `chezmoi apply`**, and no shared source can shadow one.
- The script runs on every apply, so adding, removing, or moving a skill between sources relinks on the next apply.
- These skills ship with the repo, so a fresh clone gets them before any source repo has been cloned. Keep them free of anything private — this repo is public.

## Third-party skills: dot_apm/apm.yml

Skills I did not write are declared in `dot_apm/apm.yml` and installed by [APM](https://microsoft.github.io/apm/), which `.chezmoiscripts/run_onchange_20-agent-packages.sh.tmpl` runs on apply. Add a dependency, run `chezmoi apply`. The CLI itself comes from the Brewfile (`brew "microsoft/apm/apm"`).

- Dependencies are `owner/repo`, optionally `#ref`; a monorepo subdirectory (`owner/repo/skills/<name>`) also resolves. Prefer a skills-only repo: `manaflow-ai/cmux-skills` installs in seconds where the cmux monorepo did not finish.
- **Removal is why APM and not `npx skills`.** Dropping a dependency and re-applying deletes its deployed files, and `apm prune` drops the cached package. The `skills` CLI only ever adds, so a removed entry stayed installed forever.
- `targets: [agent-skills]` pins deployment to `~/.agents/skills`. Without it APM auto-detects `~/.claude/skills` too and writes real dirs there, which shadow the fan-out script's links.
- `apm install <pkg>` appends to the *deployed* `~/.apm/apm.yml`, which the next apply overwrites. Add dependencies to the source file instead.
- `~/.apm/apm.lock.yaml` pins each dependency's resolved commit but is unmanaged, so machines drift. `apm update` refreshes; a `#tag` or `#sha` in the manifest pins for real.
- Upstream guidance that conflicts with how this repo works is corrected by an override in `AGENTS.md`, not by narrowing where the skill installs — the cmux config skills' write path is the worked example.

## Mechanics

- External sources are cloned to `~/.agents/sources/<name>` via `.chezmoiexternal.toml.tmpl`; adding a source also requires adding its path to `SOURCE_ROOTS` in `.chezmoiscripts/run_after_agent-skills.sh.tmpl` (array order = collision precedence, first wins).
- Real dirs in `~/.agents/skills` beat source symlinks on name collision.
- Per-machine gating: profile conditionals in `.chezmoiexternal.toml.tmpl`, OS gating in `.chezmoiignore`. Personal-account repos resolve via the `personal.github.com` SSH alias on work machines and plain `github.com` elsewhere.
- Never touch `~/.agents/.skill-lock.json` — owned by the `npx skills` CLI, which wipes formats it doesn't recognize.
- Remove a skill by deleting it from its source repo; the next `chezmoi apply` prunes its links.
