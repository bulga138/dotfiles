# OpenCode Agents

Specialized AI agents for software development, optimized for minimal context overlap and maximum token efficiency.

## Agent Overview

| Agent            | Role              | Model                          | When to Use                          |
| ---------------- | ----------------- | ------------------------------ | ------------------------------------ |
| **orchestrator** | Architecture/Plan | google/gemini-3.1-flash-lite-preview | Complex multi-step tasks, Planning   |
| **coder**        | Developer         | ollama/qwen3-coder:30b         | Implementation, bug fixes            |
| **qa**           | Review & Tests    | opencode/minimax-m2.5-free     | Security, code review, test coverage |
| **docs**         | Technical writer  | ollama/qwen3.5:9b              | Maintain CONTEXT.md and writing docs |

## Model Routing & Easy Tasking

By default, the system mandates routing to `ollama/qwen3.5:0.8b` for simple system/OS operations to conserve tokens. Larger models are engaged via the Orchestrator based on task complexity.

| Task Type                           | Model                          | Est. Tokens |
| ----------------------------------- | ------------------------------ | ----------- |
| Easy Tasking / File operations      | ollama/qwen3.5:0.8b            | ~500        |
| Documentation & Summaries           | ollama/qwen3.5:9b              | ~1000       |
| Review & Testing                    | opencode/minimax-m2.5-free     | ~1500       |
| Standard coding                     | ollama/qwen3-coder:30b         | ~2000       |
| Complex Architecture (Orchestrator) | google/gemini-3.1-flash-lite-preview     | ~3500+      |

## Workflow

User Request → [orchestrator] → [coder] → [qa] → [docs] → Complete

_(Note: Simple OS operations short-circuit directly to `ollama/qwen3.5:0.8b` without invoking the full lifecycle)._

## Best Practices

- **Minimal Context Overlap**: Agents are condensed (e.g. `qa` handles both test engineering and reviewing) to prevent re-reading the code multiple times.
- **Persistent Memory**: The `@docs` agent maintains a centralized `CONTEXT.md` file so all agents are aligned on project state and technical decisions.
- **Easy Task Fast-Path**: Leverage the `small_model` default for basic OS operations.
- **Respect agent boundaries**: (`@coder` executes exclusively, `@qa` validates exclusively).
