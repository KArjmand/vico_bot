<p align="center">
  <img src="logo.png" alt="Vicobot" width="250" height="150">
  <h1 align="center">Vicobot</h1>
  <p align="center"><strong>Lightweight AI agent in a single binary — built with V.</strong></p>
  <p align="center">
    <img src="https://img.shields.io/badge/binary-~1.2MB-brightgreen" alt="Binary Size">
    <img src="https://img.shields.io/badge/docker-~15MB-blue" alt="Docker Size">
    <img src="https://img.shields.io/badge/built_with-V-5d87bf?logo=v" alt="V">
    <img src="https://img.shields.io/badge/RAM-~2MB-orange" alt="Memory Usage">
    <img src="https://img.shields.io/badge/license-MIT-yellow" alt="License">
  </p>
</p>

---

Vicobot is a [V](https://vlang.io/) rewrite of [picobot](https://github.com/louisho5/picobot) — a lightweight self-hosted AI chatbot. It gives you persistent memory, tool calling, skills, and Telegram integration in a single ~1.2MB binary.

No Python. No Node. No 500MB container. Just one binary and a config file.

## Why Vicobot?

| | Vicobot | Typical Agent Frameworks |
|---|---|---|
| **Binary size** | ~1.2MB | 200MB+ (Python + deps) |
| **Docker image** | ~15MB (Alpine) | 500MB–1GB+ |
| **Cold start** | Instant | 5–30 seconds |
| **RAM usage** | ~2MB idle | 200MB–1GB |
| **Dependencies** | Zero (single binary) | Python, pip, venv, Node… |

Runs on a **$5/mo VPS**, a Raspberry Pi, or any Linux box.

## Quick Start

### Docker

```bash
cd docker
cp .env.example .env
# Edit .env with your API key
docker-compose build --no-cache
docker-compose up -d
```

### From Source

```bash
# Build
v -o vicobot src/main.v

# Initialize config + workspace
./vicobot onboard

# Single query
./vicobot agent -m "Hello!"

# Long-running mode (Telegram, etc.)
./vicobot gateway
```

## Architecture

Messages flow through a **Chat Hub** into the **Agent Loop**, which builds context from memory/sessions/skills, calls the LLM via OpenAI-compatible API, and executes tools before sending replies back.

- **Channel** — Communication channels (Telegram, etc.)
- **Agent Loop** — Context building, LLM calls, tool execution
- **Memory** — Daily notes + long-term storage with semantic search
- **Skills** — Modular knowledge packages

## Features

### Built-in Tools

| Tool | What it does |
|------|-------------|
| `filesystem` | Read, write, list files |
| `exec` | Run shell commands |
| `web` | Fetch web pages and APIs |
| `message` | Send messages to channels |
| `spawn` | Launch background subagents |
| `cron` | Schedule recurring tasks |
| `write_memory` | Persist information across sessions |
| `create_skill` | Create reusable skill packages |
| `list_skills` | List available skills |
| `read_skill` | Read a skill's content |
| `delete_skill` | Remove a skill |

### Persistent Memory

- **Daily notes** — auto-organized by date
- **Long-term memory** — survives restarts
- **Ranked recall** — retrieves relevant memories

```bash
vicobot memory recent --days 7     # this week's notes
vicobot memory rank -q "meeting"   # search memories
```

### Skills System

Teach your agent new tricks. Skills are markdown files in `~/.vicobot/workspace/skills/`.

```
You: "Create a skill for checking weather using curl wttr.in"
Agent: Created skill "weather"
```

### Telegram Integration

1. Message [@BotFather](https://t.me/BotFather) — `/newbot` — copy token
2. Add to config or `TELEGRAM_BOT_TOKEN` env var
3. Run `vicobot gateway`

### Heartbeat

Periodic check (default: 60s) reads `HEARTBEAT.md` for scheduled tasks.

## Configuration

Config at `~/.vicobot/config.json`:

```json
{
  "agents": {
    "defaults": {
      "model": "google/gemini-2.5-flash",
      "maxTokens": 8192,
      "temperature": 0.7,
      "maxToolIterations": 200
    }
  },
  "providers": {
    "openai": {
      "apiKey": "sk-or-v1-YOUR_KEY",
      "apiBase": "https://openrouter.ai/api/v1"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "YOUR_BOT_TOKEN",
      "allowFrom": ["YOUR_USER_ID"]
    }
  }
}
```

Works with any **OpenAI-compatible API** (OpenAI, OpenRouter, Ollama, etc.).

## CLI Reference

```
vicobot version                        # print version
vicobot onboard                        # create config + workspace
vicobot agent -m "..."                 # one-shot query
vicobot gateway                        # long-running mode
vicobot memory read today|long         # read memory
vicobot memory append today|long -c "" # append to memory
vicobot memory recent --days N         # recent N days
vicobot memory rank -q "query"         # search memories
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | [V](https://vlang.io/) |
| LLM providers | OpenAI-compatible API |
| Telegram | Raw Bot API (net.http) |
| HTTP / JSON | V standard library |
| Container | Alpine Linux (multi-stage build) |

Zero external dependencies. Everything uses the V standard library.

## Project Structure

```
src/
├── main.v           # CLI entry point
├── chat/            # Message hub
├── channels/        # Telegram integration
├── config/          # Config loading
├── agent/           # Agent loop, tools
├── memory/          # Memory storage
├── cron/            # Job scheduler
├── providers/       # LLM providers
├── session/         # Session manager
└── heartbeat/       # Periodic tasks
docker/              # Docker deployment
```

## Building

```bash
# Development
v run src/main.v

# Production binary
v -prod -cflags "-Os -flto -s" -o vicobot src/main.v

# Cross-compile for ARM
v -prod -os linux -arch arm64 -o vicobot-arm64 src/main.v
```

## Docs

- [AGENTS.md](AGENTS.md) — Development guide (build, code style, patterns)
- [docker/README.md](docker/README.md) — Docker deployment

## License

MIT
