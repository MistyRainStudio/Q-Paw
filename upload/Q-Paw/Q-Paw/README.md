<div align="center">

# 🐾 Q-Paw Portable

### QwenPaw USB Launcher — Plug in and use, pull out and go

[![GitHub](https://img.shields.io/badge/GitHub-MistyRainStudio%2FQ--Paw-181717?logo=github)](https://github.com/MistyRainStudio/Q-Paw)
[![QwenPaw](https://img.shields.io/badge/Powered%20by-QwenPaw-FF6B35?logo=python)](https://github.com/agentscope-ai/QwenPaw)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Turn QwenPaw into a USB portable app. Carry your AI assistant wherever you go.**

English | [中文](README_zh.md)

</div>

---

## ✨ What is Q-Paw?

**Q-Paw** packages [QwenPaw](https://github.com/agentscope-ai/QwenPaw) into a USB portable version, inspired by [U-Claw](https://github.com/dongsheng123132/u-claw). The name comes from **Q**wen + **Paw**, meaning the wisdom of Qwen and the warmth of a paw — a digital companion you carry with you 🐾.

QwenPaw is an open-source AI agent framework by the AgentScope team, supporting tool calling, file operations, code execution, multi-turn conversations, and more. Q-Paw makes it truly portable — all programs, configurations, data, and models stay on the USB drive. When you remove the USB, no traces are left on the host PC.

### Key Features

| Feature | Description |
|---------|-------------|
| 🖥️ **One-Click Menu** | `QPaw.exe` is only 755KB, providing a visual menu for install, launch, configure, and model management |
| 🔌 **Plug & Play** | Insert USB, double-click `QPaw.exe` to start — no installation on the host PC |
| 🚀 **No Traces Left** | All data stays on the USB drive (including Python cache, pip/uv cache, model cache, etc.) |
| ⚡ **Ultra-Fast Install** | Uses uv by default (10-100x faster than pip), with automatic pip fallback |
| 🌐 **No VPN Required** | Dependencies download from Aliyun / Tsinghua / Huawei mirrors — friendly for China networks |
| 📦 **On-Demand Models** | Default online mode doesn't download models; download or import models as needed |
| ⚙️ **Interactive Config** | Built-in Python config editor directly modifies JSON files (providers, models, API keys, etc.) |
| 🛡️ **Security** | Inherits QwenPaw's three-layer security (tool guard / file guard / skill scanner) |
| 💻 **Cross-Platform** | Windows (one-click menu + scripts) / macOS / Linux (shell scripts) |

---

## 🚀 Quick Start

### Windows (Recommended)

```
1. Copy the entire Q-Paw folder to your USB drive root
2. Double-click QPaw.exe
3. Select [1] Install Environment
4. Select [2] Launch QwenPaw
```

### macOS / Linux

```bash
cd macOS_Linux
chmod +x setup.sh && ./setup.sh     # Install
./launch.sh                          # Launch QwenPaw
```

### Using Scripts (Windows)

If you prefer not to use `QPaw.exe`, you can directly double-click scripts in the `Windows/` folder:

| Script | Function |
|--------|----------|
| `setup.bat` | Install environment (required for first use) |
| `launch.bat` | Launch QwenPaw |
| `configure.bat` | Interactive configuration editor |
| `model-manager.bat` | Model management (download/import/delete) |
| `update.bat` | Update QwenPaw + modelscope + uv |
| `migrate.bat` | Migrate data from an old Q-Paw |
| `cleanup.bat` | Clean caches and temp files |

---

## 📦 Installation Process Explained

When you run setup (`QPaw.exe → [1]` or `setup.bat` / `setup.sh`), the script automatically performs these 6 steps:

### Step 1: Install uv Package Manager

uv is an ultra-fast Python package manager developed by Astral (the Ruff team), 10-100x faster than pip. The script downloads it from NPMMirror (China mirror) first, falling back to GitHub if needed. The binary is placed in `bin/uv.exe` (Windows) or `bin/uv` (macOS/Linux).

If uv download fails, the script automatically falls back to pip — subsequent steps are unaffected.

### Step 2: Download Portable Python

Downloads different Python environments based on the OS:

- **Windows**: Python 3.11 Embedded (~15MB), from NPMMirror / Huawei Cloud / python.org (3-level mirrors). Automatically configures pip support after extraction.
- **macOS**: Miniconda (auto-adapts to Apple Silicon / Intel), from Tsinghua TUNA mirror.
- **Linux**: Miniconda (x86_64), also from Tsinghua TUNA mirror.

All Python environments are installed to the USB's `python/`, `python-macos/`, or `python-linux/` directories — no impact on the host system's Python.

### Step 3: Install QwenPaw

Uses uv (preferred) or pip (fallback) to install `qwenpaw` and its dependencies. The installation tries four mirror sources in order:

1. Aliyun PyPI Mirror
2. Tsinghua TUNA PyPI Mirror
3. Huawei Cloud PyPI Mirror
4. PyPI Official

Ensures successful installation even in China network environments. If QwenPaw is already installed, this step is automatically skipped.

### Step 4: Create Portable Directory Structure

Creates the following directories on the USB:

```
data/          → QwenPaw working directory (config, chat history, skills, etc.)
config/        → Portable mode configuration files
models/        → Local model storage directory
logs/          → Runtime logs
scripts/       → Helper scripts (e.g., config editor)
bin/           → uv binary files
```

### Step 5: Generate Portable Mode Configuration

Automatically generates `config/portable.env` containing portable mode flags, path configurations, package manager type, model running mode (default: online), and pip mirror URL. If the file already exists, it's skipped to preserve user customizations.

### Step 6: Initialize QwenPaw Workspace

QwenPaw requires `qwenpaw init` before first run to generate configuration files and workspace structure. Q-Paw handles this automatically, pointing the workspace to the USB's `data/` directory. Generated files include:

- `data/config.json` — Main config file (Agent settings, security config, channel config, etc.)
- `data/HEARTBEAT.md` — QwenPaw workspace heartbeat file
- `data/.secret/` — Sensitive data directory (encrypted API key storage, etc.)
- `data/.backups/` — Configuration backup directory

All cache directories that could write to the host PC are redirected to the USB:

| Environment Variable | Points To | Purpose |
|---------------------|-----------|---------|
| `PIP_CACHE_DIR` | `cache/pip/` | pip package cache |
| `UV_CACHE_DIR` | `cache/uv/` | uv package cache |
| `MODELSCOPE_CACHE` | `cache/modelscope/` | ModelScope model cache |
| `HUGGINGFACE_HUB_CACHE` | `cache/huggingface/` | HuggingFace model cache |

> If initialization fails, the script provides instructions for manual execution. If setup is interrupted, simply re-run — completed steps are automatically skipped.

---

## 📁 File Structure

```
Q-Paw/                          ← USB Root
├── QPaw.exe                    # One-click menu (755KB, Go, standalone)
│
├── Windows/                    # Windows scripts
│   ├── setup.bat               #   Install environment (6 steps, automatic)
│   ├── launch.bat              #   Launch QwenPaw (auto-detects environment)
│   ├── configure.bat           #   Interactive config editor entry point
│   ├── model-manager.bat       #   Model management (download/import/delete/switch mode)
│   ├── update.bat              #   Update (uv + QwenPaw + modelscope)
│   ├── migrate.bat             #   Data migration (merge from old version)
│   └── cleanup.bat             #   Clean caches and temp files
│
├── macOS_Linux/                # macOS / Linux scripts
│   ├── setup.sh                #   Install environment
│   ├── launch.sh               #   Launch QwenPaw
│   ├── configure.sh            #   Interactive config editor entry point
│   ├── model-manager.sh        #   Model management
│   ├── update.sh               #   Update
│   ├── migrate.sh              #   Data migration
│   └── cleanup.sh              #   Clean caches
│
├── bin/                        # Binary tools
│   ├── uv.exe / uv             #   uv package manager (45MB, 10-100x faster than pip)
│   └── uvx.exe / uvx           #   uv tool runner
│
├── scripts/                    # Helper scripts
│   └── qpaw-config.py          #   Interactive config editor (Python)
│
├── installer/                  # QPaw.exe source code
│   ├── main.go                 #   Go source
│   └── go.mod                  #   Go module definition
│
├── config/                     # Configuration files
│   ├── portable.env            #   Portable mode env vars (auto-generated by setup)
│   ├── portable.env.example    #   Portable mode config example
│   ├── qwenpaw-config.example.yaml  # QwenPaw config example
│   └── custom-models.example.yaml   # Custom models config example
│
├── python/                     # Windows portable Python (Embedded)
├── python-macos/               # macOS portable Python (Miniconda)
├── python-linux/               # Linux portable Python (Miniconda)
│
├── models/                     # Local model directory (on demand, empty by default)
├── data/                       # QwenPaw working directory (QWENPAW_WORKING_DIR)
│   ├── config.json             #   Main config file
│   ├── HEARTBEAT.md            #   Workspace heartbeat
│   ├── .secret/                #   Sensitive data (encrypted API keys)
│   │   └── providers/          #     LLM provider configs
│   │       ├── active_model.json     Active model selection
│   │       ├── builtin/              Built-in provider configs
│   │       └── custom/               Custom provider configs
│   └── .backups/               #   Config backups
├── cache/                      # Cache directory (redirected to USB)
│   ├── pip/                    #   pip cache
│   ├── uv/                     #   uv cache
│   ├── modelscope/             #   ModelScope cache
│   └── huggingface/            #   HuggingFace cache
├── logs/                       # Log files
├── README.md                   # English docs (this file)
└── README_zh.md                # Chinese docs
```

---

## 🖥️ QPaw.exe One-Click Menu

`QPaw.exe` is a lightweight menu program written in Go (only 755KB), providing 7 major functions:

```
╔═══════════════════════════════════════════╗
║            Q-Paw 便携助手 v2.0            ║
║        QwenPaw U盘启动器 - 即插即用       ║
╚═══════════════════════════════════════════╝

┌─ 系统状态 ────────────────────────────────┐
│  Python:  Installed        uv: Installed    │
│  QwenPaw: Installed        Models: 0        │
│  Workspace: Initialized                     │
│  Running Mode: Online                       │
└──────────────────────────────────────────┘

[1] 📥 Install      First-time setup (install + init workspace)
[2] 🚀 Launch       Start QwenPaw (online/offline mode)
[3] 📦 Models       Download/import/delete local models
[4] 🔄 Update       Update QwenPaw + modelscope + uv
[5] 🔀 Migrate      Merge data from old Q-Paw
[6] ⚙️  Configure    Edit API Key / running mode / etc.
[7] 🧹 Cleanup      Clean caches and temp files

[0] Exit
```

On startup, it automatically checks the installation status of Python, uv, QwenPaw, and workspace initialization.

---

## ⚙️ Interactive Configuration Editor

Q-Paw includes a powerful interactive configuration editor (`scripts/qpaw-config.py`) that directly modifies QwenPaw's JSON configuration files — no manual editing required.

### How to Launch

- **Windows**: `QPaw.exe → [6] Configure`, or double-click `Windows/configure.bat`
- **macOS/Linux**: Run `macOS_Linux/configure.sh`

### Six Functional Modules

#### 1. Model & Provider Configuration

Supports 9 built-in providers + unlimited custom providers:

| Built-in Provider | Type | Default Model |
|-------------------|------|---------------|
| DashScope (Alibaba Cloud) | Cloud | qwen-plus |
| OpenAI | Cloud | gpt-4o |
| OpenRouter | Cloud | openai/gpt-4o |
| ModelScope | Cloud | qwen-plus |
| Anthropic (Claude) | Cloud | claude-sonnet-4-20250514 |
| Google Gemini | Cloud | gemini-2.0-flash |
| ZhipuAI (GLM) | Cloud | glm-4-plus |
| Ollama | Local | qwen2.5:7b |
| LM Studio | Local | default |

Supported operations:
- **Switch Provider** — Select from list; provider config file is auto-generated
- **Set API Key** — Key is written to provider config; QwenPaw auto-encrypts on startup
- **Switch Model** — Select from preset list or manually enter model name
- **Modify API URL** — Customize base_url for proxies, intranet forwarding, or third-party compatible APIs
- **Add Custom Provider** — Support any OpenAI-compatible API (DeepSeek, SiliconFlow, vLLM, etc.)
- **Test Connection** — Verify API key and URL availability, display available models

#### 2. Running Mode Switch

- **Online Mode** — Calls cloud API, requires network
- **Offline Mode** — Local model inference, fully offline
- **Dual-Mode Routing** — Simple tasks go local, complex tasks go cloud, balancing speed and quality

#### 3. Agent Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Language | zh | Conversation language (zh/en/ru) |
| Approval Level | AUTO | STRICT (confirm each) / SMART (dangerous only) / AUTO (auto-execute) / OFF (fully auto) |
| Max Reasoning Iterations | 100 | Maximum tool call rounds per conversation |
| Context Length | 131072 | Maximum input tokens |
| Shell Command Timeout | 60s | Timeout for Shell command execution |

#### 4. Security Configuration

- **Tool Guard** — Blocks dangerous command execution (e.g., `rm -rf /`)
- **File Guard** — Restricts file access to USB directories
- **Skill Scanner** — Security check before installing new skills

#### 5. Configuration Overview

Displays a complete summary of all current configurations, including active model, provider details, Agent settings, security config, channel config, and running mode.

#### 6. Advanced JSON Editor

Directly edit `config.json`, `active_model.json`, or provider config files. Auto-backups before editing (keeps last 3 backups); format errors are caught without saving.

---

## 🌐 Two Running Modes

### Online Mode (Default)

Use AI through cloud APIs — no model download required. Only need network + API Key.

Recommended API providers:

| Provider | Features | Free Tier | Get API Key |
|----------|----------|-----------|-------------|
| 🔵 **DashScope** | Qwen official API, direct in China | Free tier for new users | [dashscope.console.aliyun.com](https://dashscope.console.aliyun.com/) |
| 🟢 **OpenAI** | GPT-4o etc., proxy support | Paid | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| 🟣 **OpenRouter** | 100+ models, unified API, some free | Some models free | [openrouter.ai/keys](https://openrouter.ai/keys) |
| 🟣 **ModelScope** | Direct in China, 2000 free calls/day | 2000 calls/day | [modelscope.cn/my/myaccesstoken](https://modelscope.cn/my/myaccesstoken) |

Quick API Key setup:

```bash
# Method 1: Config editor (recommended)
QPaw.exe → [6] Configure → [1] Model & Provider → Set API Key

# Method 2: Edit config/portable.env
QP_API_PROVIDER=dashscope
QP_API_KEY=sk-your-api-key-here

# Method 3: Add custom provider via config editor
Supports DeepSeek, SiliconFlow, ZhipuAI, or any OpenAI-compatible API
```

### Offline Mode

Use local model inference — fully offline, data stays on the USB. Requires downloading models first via the model manager.

Recommended offline models:

| Model | Size | Description |
|-------|------|-------------|
| **QwenPaw-Flash-2B** (recommended) | ~4GB | Optimized for QwenPaw Agent scenarios |
| Qwen2.5-3B-Instruct | ~6GB | Balanced choice |
| Qwen2.5-7B-Instruct | ~15GB | Best quality, requires larger USB |
| Qwen2.5-1.5B-Instruct | ~3GB | Lightweight, suitable for small USBs |

How to switch:

```bash
# Method 1: QPaw.exe → [6] Configure → [2] Running Mode
# Method 2: QPaw.exe → [3] Models → [4] Switch online/offline mode
# Method 3: Edit QP_MODEL_MODE=online / local in config/portable.env
```

---

## 📦 Model Management

The model manager (`model-manager.bat` / `model-manager.sh`) provides these features:

### Download Models

Download directly from ModelScope to the USB's `models/` directory. Preset model list included (QwenPaw-Flash-2B, Qwen2.5-7B, etc.), or enter a custom ModelScope path to download any model (e.g., `deepseek-ai/DeepSeek-V3`).

### Import Models

Import existing model files from your local computer, copying them to the USB's `models/` directory.

### Delete Models

Remove unneeded models from the USB to free up space.

### Switch Online/Offline Mode

One-click switch of `QP_MODEL_MODE` in `config/portable.env` — no manual file editing needed.

### Install Python Packages

Install additional Python packages via uv (preferred) or pip, using China mirrors automatically.

### Configure Download Mirror

Switch between Aliyun, Tsinghua, Huawei Cloud, and PyPI official pip mirrors.

---

## 🔄 Update

The update script performs three steps in order:

1. **Update uv** — Download the latest uv from NPMMirror and replace the old version
2. **Update QwenPaw** — Upgrade to the latest version using uv/pip
3. **Update modelscope** — Upgrade ModelScope SDK simultaneously

All updates use China mirrors first, with automatic fallback to official sources.

---

## 🔀 Data Migration

When upgrading to a new version of Q-Paw, use the migration tool to merge data from the old USB:

- **Models Migration** — Copy models from old USB to new USB; existing models are automatically skipped
- **Data Migration** — Merge chat history, skills, etc.; newer files are preserved
- **Config Merge** — Smart merge of `portable.env`; keeps new defaults + old user customizations

Supports "merge all" or "custom selection" of what to migrate.

---

## 🧹 Cache Cleanup

The cleanup tool provides 6 cleaning options:

| Option | Cleans | Description |
|--------|--------|-------------|
| Log files | `logs/*` | Runtime logs |
| Python cache | `__pycache__`, `*.pyc` | Python compiled cache |
| pip cache | pip cache | Downloaded package cache |
| uv cache | uv cache | Downloaded package cache |
| Temp files | `*.tmp`, `*.log`, `temp/` | Installation residuals |
| Clean all | All above | One-click cleanup |

Recommended when USB space is low. Regular cleanup can free up hundreds of MB.

---

## 🔧 Configuration Files Explained

### config/portable.env

The core portable mode configuration file, auto-generated by the `setup` script. Main settings:

```env
QP_PORTABLE_MODE=1                          # Portable mode flag
QP_MODEL_MODE=online                        # Running mode: online / local
QP_API_PROVIDER=dashscope                   # API provider
QP_API_KEY=sk-your-key                      # API key
QP_PKG_MGR=uv                               # Package manager: uv / pip
QP_PIP_MIRROR=https://mirrors.aliyun.com/pypi/simple/  # pip mirror
QP_TOOL_GUARD=1                             # Tool guard switch
QP_FILE_GUARD=1                             # File guard switch
QP_SKILL_SCAN=1                             # Skill scanner switch
```

### data/config.json

QwenPaw's main configuration file, generated by `qwenpaw init`. Contains:

- `agents` — Agent config (language, approval level, reasoning parameters, LLM routing, etc.)
- `channels` — Channel config (DingTalk, Feishu, QQ, etc.)
- `security` — Security config (tool guard, file guard, skill scanner)
- Other QwenPaw framework configurations

### data/.secret/providers/

LLM provider configuration directory:

- `active_model.json` — Current active provider and model selection
- `builtin/` — Built-in provider configs (DashScope, OpenAI, etc.)
- `custom/` — User-added custom provider configs

> QwenPaw automatically encrypts API keys on startup — plaintext keys are not persisted on disk.

---

## 📋 Package Manager: uv + pip Dual Support

Q-Paw uses **uv** as the default package manager, with **pip** as fallback. uv is developed by the Astral team (Ruff creators), written in Rust, and 10-100x faster than pip.

| Component | Package Manager | Mirror Source |
|-----------|----------------|---------------|
| uv binary | — | NPMMirror / GitHub |
| Python Embedded (Windows) | — | NPMMirror / Huawei Cloud / python.org |
| Miniconda (macOS/Linux) | — | Tsinghua TUNA / Official |
| QwenPaw etc. | uv first, pip fallback | Aliyun / Tsinghua / Huawei / Official |
| ModelScope models | — | ModelScope (direct in China) |

Mirror source priority: Aliyun → Tsinghua TUNA → Huawei Cloud → Official

---

## 🛡️ Security Features

Q-Paw inherits QwenPaw's three-layer security system, with enhanced file access restrictions in portable mode:

### Tool Guard

Intercepts all dangerous command executions. When an Agent attempts to execute high-risk Shell commands (e.g., `rm -rf`, disk formatting), the Tool Guard automatically blocks and requires user confirmation. Approval levels: STRICT (confirm each), SMART (dangerous only), AUTO (auto-execute), OFF (fully auto).

### File Guard

Restricts Agent's file access scope. In portable mode, only the USB's `data/` and `models/` directories are accessible by default, preventing Agents from accidentally modifying the host PC's file system.

### Skill Scanner

Performs security checks before installing new Skills, scanning skill code for suspicious patterns to prevent malicious code injection.

### Portable Data Isolation

All caches and data are redirected to the USB — no traces left on the host PC after removal:

- `QWENPAW_WORKING_DIR` → USB `data/`
- `QWENPAW_SECRET_DIR` → USB `data/.secret/`
- `PIP_CACHE_DIR` → USB `cache/pip/`
- `UV_CACHE_DIR` → USB `cache/uv/`
- `MODELSCOPE_CACHE` → USB `cache/modelscope/`
- `HUGGINGFACE_HUB_CACHE` → USB `cache/huggingface/`

---

## 💾 USB Requirements

| Item | Minimum | Recommended |
|------|---------|-------------|
| Capacity | 8GB (no models) | 32GB+ (with local models) |
| Interface | USB 2.0 | USB 3.0+ (much faster model loading) |
| Format | FAT32 / exFAT | exFAT (supports files >4GB) |

> Online mode only needs an 8GB USB. For offline models, 32GB+ USB 3.0 is recommended as model files are typically 4-15GB.

---

## ❓ FAQ

### Q: Can I just plug in and use it?

First time requires setup: double-click `QPaw.exe` and select [1] Install, or run `setup.bat` / `./setup.sh`. Setup takes about 2-15 minutes (depending on network speed; uv mode is faster). After that, simply launch every time you plug in the USB.

### Q: Do I need local models?

No! The default is online mode — use AI through cloud APIs. You only need network and an API Key.

### Q: Will data be left on the host PC after removing the USB?

No. Q-Paw redirects all data (Python cache, pip/uv cache, model cache, working directory, etc.) to the USB. No personal data or configuration is left on the host PC after removal.

### Q: How to upgrade Q-Paw without losing data?

Use `QPaw.exe → [5] Migrate` or run `migrate.bat` / `migrate.sh` to merge models, chat history, and config from the old USB to the new one.

### Q: How to update QwenPaw to the latest version?

Three ways to update:
1. **QPaw.exe** → Select [4] Update
2. **Script**: Double-click `update.bat` (Windows) or run `./update.sh` (macOS/Linux)
3. **Manual**: Run `uv pip install --upgrade qwenpaw` or `python -m pip install --upgrade qwenpaw`

The update script also updates the `modelscope` SDK and `uv` package manager.

### Q: What if setup is interrupted?

Simply re-run the setup script. It automatically detects already-installed components (Python, uv, QwenPaw, workspace) and skips them, only executing incomplete steps.

### Q: How to add a custom API provider (e.g., DeepSeek, SiliconFlow)?

Run the config editor (`QPaw.exe → [6] Configure → [1] Model & Provider → [5] Add Custom Provider`), enter provider ID, name, API URL, and API Key. Supports any OpenAI-compatible API.

### Q: How to use with a proxy?

Run the config editor, select "Modify API URL", and change the base_url to your proxy address. For example, change OpenAI's base_url from `https://api.openai.com/v1` to your proxy URL.

---

## 🏗️ Building QPaw.exe from Source

If you want to compile `QPaw.exe` yourself:

```bash
cd installer
go build -ldflags="-s -w" -o ../QPaw.exe .
# Optional: UPX compression to reduce size
upx --best ../QPaw.exe
```

Build requirements: Go 1.21+, optional UPX (for compression).

---

## 🔄 Comparison with U-Claw

| Feature | U-Claw | Q-Paw |
|---------|--------|-------|
| Base Framework | OpenClaw (Node.js) | QwenPaw / AgentScope (Python) |
| Package Manager | npm | uv (10-100x faster) + pip (compat) |
| Portable Runtime | Node.js Embedded | Python Embedded / Miniconda |
| Model Strategy | Included by default | Not downloaded by default, on-demand |
| One-Click Menu | QPawWizard.exe (69MB, .NET 8) | QPaw.exe (755KB, Go) |
| Config Editor | None | Interactive Python editor, modifies JSON directly |
| Security | Basic | Three-layer security system |
| Custom Providers | Not supported | Supports OpenAI-compatible APIs |

---

## 🤝 Credits

- [QwenPaw](https://github.com/agentscope-ai/QwenPaw) — Open-source AI agent assistant by the AgentScope team
- [U-Claw](https://github.com/dongsheng123132/u-claw) — USB portable solution inspiration
- [AgentScope](https://github.com/modelscope/agentscope) — Multi-agent framework
- [uv](https://github.com/astral-sh/uv) — Extremely fast Python package manager

---

## 📄 License

This project is open-sourced under the [MIT License](LICENSE). QwenPaw itself follows its own independent open-source license.
