# shiny-mcp-go

A minimal **MCP (Model Context Protocol) server** written in Go.

It exposes a single tool called `add` that takes two numbers and returns
their sum. It's meant as a first MCP server — small enough to read in one
sitting, real enough to plug into an AI client like Claude Desktop.

---

## What is MCP?

MCP is an open protocol that lets AI applications (like Claude Desktop,
VS Code Copilot, or Cursor) talk to external tools and data sources through
a standard interface. Instead of every AI app inventing its own plugin
system, they all speak MCP.

An MCP server exposes three kinds of things:

| Primitive    | Purpose                              |
|--------------|--------------------------------------|
| **Tools**    | Actions the AI can execute           |
| **Resources**| Data the AI can read as context      |
| **Prompts**  | Reusable templates the user invokes  |

This server currently exposes one **tool**: `add`.

---

## Requirements

- **Go** 1.21 or newer — https://go.dev/dl/
- **Node.js** 22+ (only needed for the MCP Inspector) — https://nodejs.org/
- **Make** (optional, for the helper commands) — `choco install make` on Windows

---

## Project layout
