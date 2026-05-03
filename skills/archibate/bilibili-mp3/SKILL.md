---
name: bilibili-mp3
description: Download Bilibili video audio as MP3 with cover art and metadata (supports multiple URLs)
allowed-tools:
  - Bash(yt-dlp *)
  - Bash(mid3v2 *)
  - Bash(mkdir *)
  - Bash(cp *)
  - Bash(ls *)
argument-hint: "<url1> [url2] ..."
disable-model-invocation: true
arguments:
  - urls
---

# Bilibili to MP3

Download Bilibili video audio as MP3 files with embedded cover art, title, and artist metadata. Supports one or more URLs in a single invocation. Saves to `~/音乐/`.

## Inputs

- `$urls`: One or more Bilibili video URLs, space-separated (e.g. `https://www.bilibili.com/video/BV11x411g7DG` or `b23.tv` short links)

## Goal

For each URL, produce an MP3 file at `~/音乐/{artist}-{title}.mp3` with:
- Embedded cover art (FRONT_COVER)
- Title in ID3 `TIT2`
- Artist in ID3 `TPE1`
- Album in ID3 `TALB` (same as title)

## Steps

For each URL in `$urls`, execute steps 1–6. Then run step 7 once at the end.

### 1. Fetch video metadata

Use `yt-dlp -j "$url"` to get full video info as JSON. Extract:
- `title`
- `uploader` (Bilibili account name)
- `thumbnail` / `pic` (cover URL)
- `description` (may contain artist credits)

### 2. Identify artist and confirm with user

Read the description to reason about who the artist is. Common patterns in Bilibili music videos:
- `■Music：name` or `Music: name`
- `■Vocal：name` or vocals listed in description
- `作曲` / `作詞` / `編曲` / `歌` fields
- The uploader may or may not be the artist

Present the extracted **title** and **artist** to the user for confirmation using AskUserQuestion. Offer the detected artist as the first option, the uploader as a second option, and allow freeform input.

If no artist can be reasonably inferred from the description, ask the user directly.

### 3. Download audio as MP3 with thumbnail

```bash
cd /tmp && yt-dlp \
  -x --audio-format mp3 --audio-quality 0 \
  --embed-thumbnail \
  --embed-metadata \
  --convert-thumbnails jpg \
  --write-thumbnail \
  -o "bilibili_%(id)s.%(ext)s" \
  "$url"
```

This produces `/tmp/bilibili_{id}.mp3` and `/tmp/bilibili_{id}.jpg`.

**Success criteria**: Both files exist and the MP3 has non-zero size.

### 4. Set artist metadata

```bash
mid3v2 --artist "$artist" --album "$title" /tmp/bilibili_{id}.mp3
```

### 5. Copy to music directory

Before copying, check if the target file already exists:

```bash
mkdir -p ~/音乐
```

If `~/音乐/"$artist-$title.mp3"` already exists, ask the user whether to overwrite or skip. Do not overwrite without explicit confirmation.

```bash
cp /tmp/bilibili_{id}.mp3 ~/音乐/"$artist-$title.mp3"
```

### 6. Verify

```bash
mid3v2 ~/音乐/"$artist-$title.mp3"
```

Confirm that TIT2 (title), TPE1 (artist), TALB (album), and APIC (cover) are all present and correct.

**Success criteria**: The file at `~/音乐/{artist}-{title}.mp3` has all four metadata fields set correctly.

### 7. Cleanup

Remove all temporary `/tmp/bilibili_*` files created during this run.
