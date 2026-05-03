---
name: sync-translation
description: Sync a Chinese translation file with its English source by comparing sections and applying missing or outdated differences
disable-model-invocation: true
allowed-tools:
  - Read
  - Edit
  - Glob
  - Grep
when_to_use: Use when user asks to "sync translation", "update translation", "sync zh-CN", or "update Chinese translation". Also trigger when user references a translation file and asks to update or sync it with the source.
---

# Sync Translation

Compare an English source file with its Chinese translation and apply missing or changed sections.

## Goal

Make the translation file content-identical to the English source (in translated form). All sections in the source must be present and translated; no stale content remains.

## Steps

### 1. Detect file pair

Auto-detect the source/translation pair by looking for common patterns:
- `README.md` / `README.zh-CN.md`
- `CHANGELOG.md` / `CHANGELOG.zh-CN.md`
- Any `*.md` / `*.zh-CN.md` pair in the project root

If multiple pairs exist, ask the user which to sync.

**Success criteria**: Both file paths identified and confirmed.

### 2. Read both files

Read the full content of both the source and translation files.

**Success criteria**: Both files fully loaded and comparable.

### 3. Diff sections

Systematically compare sections between the two files:
- Find missing sections in the translation
- Find changed/moved content (e.g. items moved between categories)
- Find removed content that is stale in the translation

**Success criteria**: Complete list of differences identified.

### 4. Apply edits

Edit the translation file to match the source. Translate new content to match the existing style and tone of the translation file. Use the Edit tool for each change.

**Rules**:
- Preserve existing translations that are still accurate
- Match the writing style and tone of the existing translation
- Minimize the number of edits by combining adjacent changes

**Success criteria**: All identified differences resolved in the translation file.

### 5. Report changes

Summarize what was synced in a concise bulleted list.

**Success criteria**: User has a clear summary of all changes made.
