# dotfiles

My personal machine setup, managed with [chezmoi](https://www.chezmoi.io/).

chezmoi keeps one source of truth (this repo) and renders it into a real home directory.
Anything that differs per machine is a Go template, so the same repo produces a work
laptop, a personal laptop, and a Linux server without branching.

Primary target is **macOS on Apple Silicon**; Linux gets the shell, git, vim, and tmux
config and skips the Mac-only pieces.

## What you get

Installing this on a fresh Mac lands you with:

**Shell** — zsh with [antidote](https://github.com/mattmc3/antidote) managing plugins and
the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) prompt. Syntax highlighting,
history autosuggestions, extra completions, `z` for frecency-based `cd`, oh-my-zsh's git
aliases, colored man pages, and throttled background `git fetch`. Config is split into
small files under `~/.zsh/` that `.zshrc` sources in order.

**Git** — SSH-signed commits and tags, `pull.rebase`, `fetch.prune`, `rerere`, histogram
diffs, `zdiff3` conflict style, a commit-message template, and a `git dag` log alias.

**Apps** — installed by `brew bundle` from a generated `~/.Brewfile`: Docker, Ghostty,
cmux, VS Code, tmux, `gh`, `lazygit`, `tree`, `fnm`/`pyenv`/`mise`/`uv` for runtimes,
Raycast, Maccy, Fira Code. The `personal` profile adds Claude Code; the `work` profile
adds Obsidian, Codex, and Datadog's `pup`.

**Window management** — [AeroSpace](https://github.com/nikitabobko/AeroSpace) tiling WM
when `aerospaceEnabled` is true, otherwise Rectangle.

**Status bar** — [SketchyBar](https://felixkratz.github.io/SketchyBar/) when
`sketchybarEnabled` is true: installed from the `FelixKratz/formulae` tap with Hack Nerd
Font, run as a `brew services` job, with the macOS menu bar hidden in its place. Turning
the flag off stops the service and restores the normal menu bar.

**macOS defaults** — fast key repeat, Aerial screen saver, hot corners, password-on-wake,
plus the Dock/Spaces tweaks that make AeroSpace behave and the menu-bar autohide that
SketchyBar wants.

**Terminal and editors** — Ghostty (One Dark, quick terminal on `⌘\``), a vim config with
One Dark and arrow keys disabled, and a small tmux config with mouse support and vim-style
pane navigation.

**AI agent skills** — subscriptions to a set of skill repos, merged into `~/.agents/skills/`
and fanned out to each agent. No skill content lives here, only the routing. See
[Agent skills](#agent-skills).

**An SSH key** — generated on first apply if `~/.ssh/id_ed25519` is missing, and printed so
you can paste it into GitHub.

## Install

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ryjo1026
```

This clones the repo to `~/.local/share/chezmoi`, prompts for the values below, writes them
to `~/.config/chezmoi/chezmoi.toml`, renders everything into `$HOME`, and runs the
bootstrap scripts.

## Configuration

`.chezmoi.toml.tmpl` prompts for these on first init. They live in
`~/.config/chezmoi/chezmoi.toml` afterwards and can be edited by hand:

| Value | Purpose |
| --- | --- |
| `profile` | `work` or `personal` — gates Brewfile entries and the team skill source |
| `email` | git identity and the comment on the generated SSH key |
| `sshKeyTitle` | label for the generated SSH key |
| `aerospaceEnabled` | install AeroSpace and apply the WM-friendly macOS defaults |
| `sketchybarEnabled` | install SketchyBar, run it as a service, and hide the macOS menu bar |
| `gitSigningKey` | public key used to sign commits |

Fallbacks for anything unset are in `.chezmoidata/defaults.toml`.

## Repo layout

| Path | Contents |
| --- | --- |
| `dot_zsh/`, `dot_zshenv` | zsh config, plugin list, aliases, p10k prompt |
| `dot_Brewfile.tmpl` | Homebrew bundle, profile-aware |
| `dot_gitconfig.tmpl`, `dot_gitmessage` | git config and commit template |
| `dot_aerospace.toml` | AeroSpace tiling WM config (opt-in) |
| `dot_vimrc`, `dot_vim/` | vim config |
| `dot_tmux.conf` | tmux config |
| `dot_config/ghostty/`, `dot_config/cmux/` | Ghostty terminal and cmux settings |
| `dot_config/sketchybar/` | SketchyBar bar config and plugin scripts (opt-in) |
| `private_dot_homebrew/` | Homebrew third-party tap trust list, mirrors the Brewfile's taps |
| `.chezmoi.toml.tmpl` | config prompts run on `chezmoi init` |
| `.chezmoidata/defaults.toml` | default template values |
| `.chezmoiexternal.toml.tmpl` | skill source repos, cloned per machine profile |
| `.chezmoiscripts/` | bootstrap scripts (SSH key, macOS defaults, brew bundle, skill routing) |
| `.chezmoiignore` | per-OS and per-profile gating; also keeps repo-only files out of `$HOME` |
| `.githooks/pre-push` | renders every template against each target OS before push |
| `AGENTS.md`, `agents/` | context for AI agents working on this repo (`CLAUDE.md` symlinks to `AGENTS.md`) |
| `docs/` | design notes and plans |

A `dot_` prefix becomes a leading `.` in `$HOME` — `dot_vimrc` → `~/.vimrc`. A `.tmpl`
suffix means the file is rendered as a Go template. Root files *without* a `dot_` prefix
still deploy, so repo-only files like `README.md` and `AGENTS.md` are listed in
`.chezmoiignore`. See chezmoi's
[source state attributes](https://www.chezmoi.io/reference/source-state-attributes/).

## Day to day

```sh
chezmoi edit ~/.zshrc     # edit the source file behind a target
chezmoi diff              # preview what apply would change
chezmoi apply             # render source -> $HOME
chezmoi cd                # drop into the source repo
chezmoi update            # git pull + apply
chezmoi managed           # list everything chezmoi owns
```

Machine-specific shell tweaks that shouldn't be tracked go in `~/.zshrc.local`, which
`.zshrc` sources last.

## Bootstrap scripts

These run automatically during `chezmoi apply`:

| Script | What it does |
| --- | --- |
| `run_once_10-ssh-key.sh` | Generates `~/.ssh/id_ed25519` if missing, adds it to the agent, prints the public key. Once per machine. |
| `run_onchange_10-macos-defaults.sh` | Applies the macOS defaults above. macOS only. |
| `run_after_brew-bundle.sh` | Runs `brew bundle` against `~/.Brewfile` **in the background** when the Brewfile changes, so `chezmoi apply` returns immediately. Failure output lands in the shell when it finishes; a failed run leaves no stamp, so the next apply retries it. macOS only. |
| `run_onchange_after_agent-skills.sh` | Merges skill sources into `~/.agents/skills` and fans them out to agents that need it. |

## Agent skills

Skills are reusable instruction bundles for AI coding agents, in the
[Agent Skills](https://agentskills.io) format (`<name>/SKILL.md`). They route through
`~/.agents/skills/`, the cross-agent directory that Codex, Cursor, Gemini CLI, OpenCode,
and Amp read natively.

**This repo carries no skill content, only the routing.**
`.chezmoiexternal.toml.tmpl` clones each source repo into `~/.agents/sources/<name>`, and
`run_onchange_after_agent-skills.sh` merges them into `~/.agents/skills` as symlinks, then
fans that directory out to agents that don't read it natively (currently Claude Code).

| Layer | Source | Machines |
| --- | --- | --- |
| Public | [`ryjo1026/skills`](https://github.com/ryjo1026/skills) | all |
| Private | `ryjo1026/skills-private` | all |
| Team | `abridgeai/ryan-skills` | work profile only |
| Third-party | `dot_apm/apm.yml`, installed by [APM](https://microsoft.github.io/apm/) | all; skipped where `apm` is absent |
| Trial | real dirs in `~/.agents/skills/`, by hand | wherever you put them; never touched by chezmoi |

Skills are split by audience because this repo is public — see
[`agents/skill-routing.md`](agents/skill-routing.md) for how to pick a layer.

**Precedence** on name collisions: real dirs (trials) win over source symlinks; among
sources, the `SOURCES` array order in the script (private > team > public). Shadowed
skills are skipped with a warning.

**Add a skill:** commit `<name>/SKILL.md` to the source repo matching its audience, then
`chezmoi apply` (or wait out the 168h `refreshPeriod`). Deleting it from the source repo
makes the next apply prune its links.

**Add a third-party skill:** paste the vendor's install line as-is —
`~/.zsh/skills-apm.zsh` shadows `npx` so that

```sh
npx skills add humanlayer/skills --skill show-me
```

resolves each `--skill` name to its directory in the repo (`gh` reads the file tree),
appends the dependency to `dot_apm/apm.yml` **in the source dir**, and runs `chezmoi
apply`. It prints the resolved dependency and asks before writing, unless the pasted
command carried `-y` or `--all`. `--skill '*'`, `--all`, and a bare repo all become a
whole-repo dependency; `-a/--agent`, `-g`, and `--copy` are dropped, because the target
set is `apm.yml`'s job. Only `add` is intercepted — `--list` and every other subcommand
run the real CLI, and `command npx skills add …` bypasses the shim entirely.

**Add a source:** add a stanza to `.chezmoiexternal.toml.tmpl` and its name to `SOURCES` in
the script, then `chezmoi apply`. Removing it from both and deleting
`~/.agents/sources/<name>` cleanly unlinks everything it provided.

**Gating:** per-profile in the externals template's conditionals; per-OS in
`.chezmoiignore` — sources pull on Macs by default, and the Linux block ignores them (opt
one in with `!.agents/sources/<name>` plus `!.agents/sources/<name>/**`).

**Caveats:**

- Write access to a subscribed source repo is code execution for your agents.
  Branch-protect team sources; treat third-party sources like dependencies.
- `apm install <pkg>` appends to the deployed `~/.apm/apm.yml` and `npx skills add` writes
  real dirs under `~/.claude/skills` — the next apply overwrites the first and shadows the
  second. Declare third-party skills in `dot_apm/apm.yml`, or let the `npx skills add` shim
  above do it.
- The symlinks are script state, not chezmoi state — `chezmoi managed` won't list them.
- Gating a source off a machine doesn't delete already-cloned files (standard chezmoi
  ignore semantics); remove them by hand.

## Working on this repo

`.githooks/pre-push` renders every `*.tmpl` against each target combination
(`darwin/arm64`, `linux/amd64`) and aborts the push if any fails to render. Enable it:

```sh
git config core.hooksPath .githooks
```

The `includeIf` block in `dot_gitconfig.tmpl` wires this up automatically for clones at
`~/.local/share/chezmoi/`.
