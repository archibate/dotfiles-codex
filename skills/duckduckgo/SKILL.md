---
name: duckduckgo
description: Web search and content scraping via DuckDuckGo. Use this as a fallback to other web tools.
---

# DuckDuckGo Search
Use DuckDuckGo MCP by executing shell commands.

## Web search
- `npx -y mcporter call --stdio 'uvx duckduckgo-mcp-server' search query="{keyword}" max_results=10`

## Web fetch
- `npx -y mcporter call --stdio 'uvx duckduckgo-mcp-server' fetch_content url="https://..."`
