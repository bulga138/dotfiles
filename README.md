# Dotfiles & Agent Configurations

This repository acts as the central brain and configuration storage for your local developer environment, defining your PowerShell profile rules, LiteLLM API proxies, and the personalized OpenCode multi-agent framework.

---

## OpenCode Framework (`./opencode`)

You have a highly optimized, multi-agent AI system deployed in the `./opencode` directory which operates to save API tokens and avoid re-reading context.

### Agent Aliases

Instead of using generic models, you summon these specific personas directly in OpenCode (e.g., `@orchestrator`):

- **`@orchestrator`**: The project manager. Start complex tasks here. Conducts an interview, plans the architecture, and delegates all work down the chain. Configured to explicitly use **Gemini** logic.
- **`@coder`**: The builder. Listens to the orchestrator and exclusively executes logic and implementation using your local **Ollama** model (`qwen3-coder:30b`).
- **`@qa`**: The tester. Fuses code-review and test-engineering into one agent. Validates code without duplicating token reads.
- **`@docs`**: The memory bank. Constantly updates `CONTEXT.md` in your project to maintain active awareness of decisions, stack, and rules.

### Core Configuration (`opencode.json`)

The global engine limits tokens by actively routing tasks:

- **Easy Tasking**: Natively routes to `ollama/qwen3.5:0.8b` for basic OS filesystem commands.
- **Default Plan**: Uses Gemini.
- **Default Build**: Uses local 30b model.

---

## LiteLLM API Gateway (`litellm_config.yaml`)

Because top-tier reasoning engines (like Gemini 3.1 Flash Lite constraint) hit API Quota bottlenecks due to OpenCode's fast sequential execution, we use a LiteLLM Proxy.

### Config & Rate Limiting

The `litellm_config.yaml` explicitly enforces an `rpm: 14` (Requests Per Minute) rule. Instead of the Google Cloud API outright rejecting your requests with `"Resource Exhausted"`, the LiteLLM proxy intercepts the requests and smoothly trickles them into the API at exactly 14 requests per minute, preventing hard crashes.

- **To connect OpenCode to LiteLLM**: Configure a custom OpenAI provider format in `opencode.json` pointing to `http://127.0.0.1:4000/v1`.

---

## PowerShell Aliases & Functions (`./Powershell`)

Your `$PROFILE` automatically loads the directories for `Functions` and `Aliases` ensuring you have Unix-like commands seamlessly mapped in Windows PowerShell.

### Key Functions

| Command                             | Description                                                                                  |
| :---------------------------------- | :------------------------------------------------------------------------------------------- |
| `Start-LiteLLM`                     | Instantly spins up the LiteLLM background proxy using your local `litellm_config.yaml` file. |
| `Extract-Code` / `Reconstruct-Code` | Utility functions for manipulating codebase outputs.                                         |
| `Start-Venv`                        | Virtual Environment bootstrapper.                                                            |
| `Sudo`                              | Linux `sudo` functionally brought to native PowerShell.                                      |

### Utilities / Aliases

You have natively mapped classic Unix operations directly to your PowerShell session so muscle memory works smoothly:

- `touch` (Creates empty files)
- `grep` (Regex search matching)
- `ls` (Directory listing aliases)
- `kill-port` (Wraps `Stop-Process-On-Port`)
- `which` (Locates executables on PATH)

---

_Maintained actively to ensure efficient API routing and streamlined CLI flows._
