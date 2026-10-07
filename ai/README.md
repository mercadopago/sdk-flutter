# AI Context Files

This directory provides context for AI coding tools working with the
`mercadopago` repository.

## Files

| File | Purpose | Best for |
|------|---------|---------|
| `sdk-context.md` | Complete SDK reference: setup, API, examples, errors | Any AI tool — copy/paste into context |
| `claude.md` | Claude Code specific instructions | Claude Code (also see root `CLAUDE.md`) |
| `copilot.md` | GitHub Copilot instructions | Copilot in VS Code / JetBrains |
| `codex.md` | OpenAI Codex / ChatGPT instructions | OpenAI tools (also see root `AGENTS.md`) |

## Auto-loaded files

These files at the repo root are picked up automatically by their tools:

| File | Tool |
|------|------|
| `CLAUDE.md` | Claude Code |
| `AGENTS.md` | OpenAI Codex / ChatGPT Agents |
| `.github/copilot-instructions.md` | GitHub Copilot |

## Keeping these files up to date

When the SDK public API changes, update `ai/sdk-context.md` first — the
other files derive from it. The most important sections to keep current are
the code examples and the Common Errors table.
