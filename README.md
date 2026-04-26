# dotfiles-codex

Personal Codex configuration: global instructions, Codex config, and curated user skills.

## Install

```bash
git clone git@github.com:archibate/dotfiles-codex ~/.codex
```

If `~/.codex` already exists, clone elsewhere and run:

```bash
bash setup.sh
```

The setup script backs up existing `config.toml` and `AGENTS.md` before replacing them, then installs tracked skills from `skills/archibate/<name>` into Codex's direct `~/.codex/skills/<name>` runtime layout.

## What's Included

- `config.toml` - Codex model, project trust, plugin, and provider configuration
- `AGENTS.md` - global Codex behavior and coding preferences
- `skills/archibate/` - curated portable skills migrated from the Claude configuration
- `setup.sh` - installer for applying this repo to an existing Codex home

## What's Not Tracked

Local runtime state and secrets are intentionally ignored, including:

- `auth.json` and credential backups
- session history and session indexes
- SQLite state/log databases
- caches, logs, shell snapshots, and temporary files
- system-managed skills under `skills/.system`
- plugin caches under `plugins/cache`

## Skill Policy

This repo tracks a portable first pass of skills that are useful in Codex without depending on Claude-specific hooks, agents, or session tools. Claude-specific and dependency-heavy skills should be adapted deliberately before adding them here.
