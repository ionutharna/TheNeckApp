# TheStart

A starter workspace bundling all Claude Code skills, agents, and tooling built across previous projects.

## Skills (`/.claude/skills/`)

| Skill | Purpose |
|---|---|
| `brainstorming` | Creative exploration before any feature/component work |
| `start` | Guide through starting a new project idea |
| `prompt-factory` | Generate production-ready mega-prompts (69 presets, multi-format) |
| `deep-researcher` | Multi-layered research with synthesis from multiple sources |
| `SkillCreator` | Create and package new skills |
| `analyzing-financial-statements` | Financial ratio calculation from statement data |
| `creating-financial-models` | DCF, Monte Carlo, sensitivity analysis |
| `applying-brand-guidelines` | Apply corporate branding consistently |
| `competitive-ads-extractor` | Extract and analyze competitor ads from ad libraries |
| `file-organizer` | Intelligent file/folder organization across the system |
| `kris-accountant` | Belgian VAT/accounting automation (HAVI Belgium) |
| `yahoo-invoice-search` | Search Yahoo Mail for invoices via IMAP |

## Agents (`/.claude/agents/`)

| Agent | Purpose |
|---|---|
| `yahoo_agent.py` | Claude Agent SDK agent for Yahoo Mail invoice search — uses Anthropic sessions API |

## VS Code Extension (`/claude-vscode-agent/`)

Custom VS Code extension integrating Claude Code into the IDE.

## Settings

- `.claude/settings.json` — project permissions (openclaw, powershell, start commands)
- `.claude/settings.local.json` — local permissions (WebSearch, Python scripts, git, npm)

## Usage

Open this folder in VS Code and launch Claude Code. All skills will be available via `/skill-name`.
