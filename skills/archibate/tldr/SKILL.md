---
name: tldr
description: Append a one-line TLDR summary to the prior response. User-invoked via /tldr only.
disable-model-invocation: true
user-invocable: true
---

Append exactly one line as a TLDR summary of the prior response for the user to fast-read the verdict.

Format strictly:
  📌 <verdict in under 20 words>

Rules:
  - Write the verdict in the same language as your previous response.
  - Lead with the key verdict / answer / decision — not a recap of topics.
  - One sentence, hard cap 20 words.
  - No new information, no caveats, no bullet list.
  - Output ONLY that single summary line. Nothing else.
