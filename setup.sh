#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$codex_home"
codex_home="$(cd "$codex_home" && pwd)"
backup_dir="$codex_home/backups/dotfiles-codex-$(date +%Y%m%d%H%M%S)"

backup_file() {
  local path="$1"
  if [[ -e "$codex_home/$path" && "$repo_dir/$path" != "$codex_home/$path" ]]; then
    mkdir -p "$backup_dir/$(dirname "$path")"
    cp -a "$codex_home/$path" "$backup_dir/$path"
  fi
}

install_file() {
  local path="$1"
  [[ "$repo_dir/$path" == "$codex_home/$path" ]] && return 0
  backup_file "$path"
  mkdir -p "$codex_home/$(dirname "$path")"
  cp -a "$repo_dir/$path" "$codex_home/$path"
}

install_skill() {
  local name="$1"
  local src="$repo_dir/skills/archibate/$name"
  local dst="$codex_home/skills/$name"

  [[ -d "$src" ]] || return 0
  [[ "$src" == "$dst" ]] && return 0
  if [[ -e "$dst" && "$src" != "$dst" ]]; then
    mkdir -p "$backup_dir/skills"
    cp -a "$dst" "$backup_dir/skills/$name"
  fi
  mkdir -p "$codex_home/skills"
  rm -rf "$dst"
  cp -a "$src" "$dst"
}

install_file "config.toml"
install_file "AGENTS.md"

for skill in "$repo_dir"/skills/archibate/*; do
  [[ -d "$skill" ]] || continue
  name="$(basename "$skill")"
  install_skill "$name"
done

if [[ -d "$backup_dir" ]]; then
  printf 'Backups written to %s\n' "$backup_dir"
fi
printf 'Codex dotfiles installed to %s\n' "$codex_home"
