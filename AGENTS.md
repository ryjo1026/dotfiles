# Agent context

This is a **chezmoi source directory** (public repo). Files here render/deploy to `$HOME` on `chezmoi apply`.

- Always edit here, never the deployed copies in `$HOME`; run `chezmoi apply` after.
- Root files without `dot_` prefix deploy to `$HOME` too — repo-only files must be listed in `.chezmoiignore`.
- Every `*.tmpl` must render for both `darwin/arm64` and `linux/amd64` (pre-push hook enforces this).
- Per-tool shell config is its own self-guarding module in `dot_zsh/` (see `pyenv.zsh`, `mise.zsh`), auto-sourced by `.zshrc`. Guard on the tool's presence (`command -v` or `[[ -d ... ]]`) so it no-ops where absent — don't append tool setup to `dot_zshrc.tmpl`/`dot_zshrc.mac.tmpl`.

## Check the tool's official docs first

This repo configures fast-evolving tools whose flags, schemas, and capabilities change faster than any model's training data. **Before writing config for a tool, read its current official docs.** Don't infer capabilities from `--help`, a JSON schema, strings in the binary, or general knowledge — a capability you assumed missing is the usual cause of a contorted workaround. If the docs don't cover it, say so rather than quietly falling back to inference.

| Tool | Docs |
| --- | --- |
| chezmoi | https://www.chezmoi.io/ — [concepts](https://www.chezmoi.io/reference/concepts/), [source state attributes](https://www.chezmoi.io/reference/source-state-attributes/), [templates](https://www.chezmoi.io/reference/templates/), [special files](https://www.chezmoi.io/reference/special-files-and-directories/), [commands](https://www.chezmoi.io/reference/commands/) |
| Homebrew | https://docs.brew.sh/ — [Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile), [manpage](https://docs.brew.sh/Manpage) |
| cmux | its own [agent skills](https://cmux.com/docs/skills) first — the `cmux*` skills installed under `~/.agents/skills` are richer and more current than the web docs; then `cmux docs [settings\|shortcuts\|api\|browser\|agents\|dock\|sidebars]` offline, then https://cmux.com/docs |
| Ghostty | https://ghostty.org/docs |
| AeroSpace | https://nikitabobko.github.io/AeroSpace/guide |
| mise | https://mise.jdx.dev/ |
| antidote | https://getantidote.github.io/ |
| fnm | https://github.com/Schniz/fnm |
| fzf | https://junegunn.github.io/fzf/ — [shell integration](https://github.com/junegunn/fzf#setting-up-shell-integration) |

Any tool not listed: find its official docs and add a row here.

## cmux settings: override the skills' write path

cmux's own skills (`cmux-config`, `cmux-sidebar-builder`) tell you to edit `~/.config/cmux/cmux.json` and to keep a timestamped `.bak` beside it. Both are wrong here: that file is rendered from `dot_config/cmux/cmux.json.tmpl`, so a direct edit dies at the next `chezmoi apply`, and git history is the backup.

- Edit the template, run `chezmoi apply`, then `cmux reload-config` — it reloads cmux and Ghostty config in place, with no restart.
- The template carries Go conditionals and is not valid JSON. Point `cmux config validate` and the skills' `scripts/cmux-settings` helper at the rendered `~/.config/cmux/cmux.json` after apply, never at the template.
- Terminal rendering (font, cursor, theme, opacity) is Ghostty's, not cmux's: `dot_config/ghostty/config` here.
- Anything else cmux writes under `~/.config/cmux/` belongs here as `dot_config/cmux/<name>` — including a `cmux-sidebar-builder` sidebar, which lands in `~/.config/cmux/sidebars/<name>.swift`.
## The Brewfile is install-only: audit before trusting it

`brew bundle` never uninstalls, so a package installed by hand keeps working here and is silently missing from the next machine. `dot_Brewfile.tmpl` is therefore not a record of what is installed — only of what is guaranteed.

- The `auditing-brewfile` skill carries the audit and the triage procedure; its `scripts/brew-audit` lists packages installed on purpose but declared nowhere, plus the reverse drift, and exits non-zero when anything needs a decision.
- There is no ignore list, so a candidate you decline is reported again next run.
- The bundle runs detached (`.chezmoiscripts/run_after_brew-bundle.sh.tmpl`): `chezmoi apply` returns before it finishes, and its output — including a failure with the log — arrives in the terminal later. The stamp at `~/.cache/chezmoi/brew-bundle.sha256` is written only on success and is what gates the next run, so don't convert the script back to `run_onchange_` (chezmoi would mark it done at fork time and never retry a failure).
- Homebrew 7 refuses to load a formula or cask from an untrusted third-party tap, so a new tap in `dot_Brewfile.tmpl` also needs an entry in `private_dot_homebrew/private_trust.json.tmpl` — same conditionals — or `brew bundle` fails on a fresh machine with "Refusing to load … from untrusted tap". Don't fix that with `brew trust`: it rewrites `~/.homebrew/trust.json`, which chezmoi owns and will revert.
- **Never run `brew bundle cleanup --force`** to resolve the audit — it uninstalls the entire list rather than codifying it.

Detailed agent docs live in `agents/`:

- **Before creating, moving, or removing any skill (`SKILL.md`), read [`agents/skill-routing.md`](agents/skill-routing.md)** — it defines the layered routing system (repo-local / public / private / team / trial) and where a new skill must live based on its subject and audience. Skills about *this repo's* mechanics live in `skills/` here; everything else lives in a source repo. Never drop skills directly into `~/.claude/skills/`.

`CLAUDE.md` is a symlink to this file — edit here only.
