# Q-Paw Portable — QwenPaw USB Launcher

> Turn QwenPaw into a USB portable app. Plug in and use, pull out and go.

[中文文档](README_zh.md)

---

## What is Q-Paw?

**Q-Paw** packages [QwenPaw](https://github.com/agentscope-ai/QwenPaw) into a USB portable version, inspired by [U-Claw](https://github.com/dongsheng123132/u-claw). The name comes from **Q**wen + **Paw**, meaning the wisdom of Qwen and the warmth of a paw — a digital companion you carry with you 🐾.

### Key Features

| Feature | Description |
|---------|-------------|
| 🖥️ **QPaw.exe** | One-click menu — install, launch, configure, manage models (755KB) |
| 🔌 **Plug & Play** | Insert USB, double-click `QPaw.exe` to start |
| 🚀 **Portable Data** | All config and data stay on the USB drive — no traces on host PC |
| ⚡ **uv + pip** | Default uv (10-100x faster), fallback to pip — Chinese mirrors |
| 📦 **No Default Model Download** | Online mode by default; download models on demand |
| 🌐 **No VPN Required** | Dependencies from Aliyun / Tsinghua / Huawei mirrors |
| 💻 **Cross-platform** | Windows / macOS / Linux (scripts for Mac/Linux) |
| 🛡️ **Security** | Inherits QwenPaw's three-layer security (tool guard / file guard / skill scanner) |

---

## Quick Start

**Windows (Recommended):**
```
Double-click QPaw.exe     → Visual menu, one-click everything
```

**Or use scripts directly (in Windows/ folder):**
```
Double-click Windows\setup.bat    → Install environment
Double-click Windows\launch.bat   → Launch QwenPaw
Double-click Windows\model-manager.bat  → Manage models
```

**macOS / Linux (in macOS_Linux/ folder):**
```bash
cd macOS_Linux
chmod +x setup.sh && ./setup.sh     # Install
./launch.sh                          # Launch
./model-manager.sh                   # Manage models
```

Setup will automatically:
1. Download uv package manager (from NPMMirror / GitHub)
2. Download portable Python (Windows Embedded / macOS & Linux Miniconda)
3. Install QwenPaw + modelscope (uv first, pip fallback, Chinese mirrors)
4. Create portable directories (data / config / models / logs)
5. Generate portable config file (`config/portable.env`)

> Requires internet. First-time setup takes about 5-15 minutes depending on network speed.

---

## File Structure

```
Q-Paw/                          ← USB Root
├── QPaw.exe                    # 🖥️ One-click menu (755KB, standalone)
│
├── Windows/                    # Windows scripts
│   ├── setup.bat               # Initialize environment
│   ├── launch.bat              # Launch QwenPaw
│   ├── model-manager.bat       # Model manager
│   ├── update.bat              # Update (uv + QwenPaw + modelscope)
│   ├── migrate.bat             # Data migration
│   └── cleanup.bat             # Clean cache
│
├── macOS_Linux/                # macOS / Linux scripts
│   ├── setup.sh
│   ├── launch.sh
│   ├── model-manager.sh
│   ├── update.sh
│   ├── migrate.sh
│   └── cleanup.sh
│
├── bin/                        # uv.exe + uvx.exe + other binaries
├── python/                     # Windows portable Python (Embedded)
├── python-macos/               # macOS portable Python (Miniconda)
├── python-linux/               # Linux portable Python (Miniconda)
│
├── models/                     # Local model directory (on demand, empty by default)
├── config/                     # Configuration files
│   ├── portable.env            # Portable mode env vars (auto-generated)
│   ├── qwenpaw-config.yaml    # QwenPaw config
│   └── *.example               # Example configs
├── data/                       # User data (QWENPAW_WORKING_DIR)
├── logs/                       # Log files
├── scripts/                    # Helper scripts
├── README.md                   # English docs (this file)
└── README_zh.md                # Chinese docs
```

---

## Two Running Modes

| Mode | Network | Local Model | Description |
|------|---------|-------------|-------------|
| **Online** (default) | Required | Not needed | Cloud API (DashScope / OpenAI / OpenRouter / ModelScope) — fast, high quality |
| **Offline** | Not needed | Required | Local model inference — fully offline, data stays on USB |

### Online Mode Setup

1. Register at [DashScope](https://dashscope.console.aliyun.com/) and get an API Key
2. Edit `config/portable.env`:
   ```
   QP_API_PROVIDER=dashscope
   QP_API_KEY=sk-your-api-key-here
   ```

### Recommended Offline Models

| Model | Size | Description |
|-------|------|-------------|
| **QwenPaw-Flash-2B** (recommended) | ~4GB | Optimized for QwenPaw Agent scenarios |
| Qwen2.5-3B-Instruct | ~6GB | Balanced choice |
| Qwen2.5-7B-Instruct | ~15GB | Best quality, requires larger USB |

---

## Package Manager: uv + pip

Q-Paw uses **uv** as the default package manager (10-100x faster than pip), with pip as fallback:

| Component | Package Manager | Mirror Source |
|-----------|----------------|---------------|
| uv binary | — | NPMMirror / GitHub |
| Python Embedded | — | NPMMirror / Huawei Cloud / python.org |
| Miniconda | — | Tsinghua TUNA / Official |
| QwenPaw etc. | **uv first**, pip fallback | Aliyun / Tsinghua / Huawei / Official |
| ModelScope models | — | ModelScope (direct connect in China) |

---

## API Providers

| Provider | Type | Features |
|----------|------|----------|
| 🔵 **DashScope** | Cloud API | Qwen official API, direct in China, free tier |
| 🟢 **OpenAI** | Cloud API | GPT-4o etc., proxy support |
| 🟣 **OpenRouter** | Cloud API | 100+ models, unified API, some free |
| 🟣 **ModelScope** | Cloud API + Local | 2000 free calls/day, domestic, local download |

---

## USB Requirements

| Item | Minimum | Recommended |
|------|---------|-------------|
| Capacity | 8GB (no models) | 32GB+ (with local models) |
| Interface | USB 2.0 | USB 3.0+ (faster model loading) |
| Format | FAT32 / exFAT | exFAT (supports files >4GB) |

> 💡 Online mode only needs an 8GB USB. For offline models, 32GB+ USB 3.0 is recommended.

---

## FAQ

### Q: Can I just plug in and use it?
Double-click `QPaw.exe` (Windows) and select [1] to install, or run `setup.bat` / `./setup.sh` first. After that, launch anytime.

### Q: Do I have to download models?
No! Online mode works without local models. You just need network + API Key.

### Q: Will I lose data when I remove the USB?
No. All data is stored on the USB `data/` directory. Consider backing up to your computer regularly.

### Q: How to upgrade without losing data?
Use `QPaw.exe` → [5] 数据迁移, or run `migrate.bat` (Windows) / `migrate.sh` (macOS/Linux).

### Q: How to update QwenPaw to the latest version?
Three ways to update:
1. **QPaw.exe** → Select [4] Update
2. **Script**: Double-click `update.bat` (Windows) or run `./update.sh` (macOS/Linux)
3. **Manual**: Run `uv pip install --upgrade qwenpaw` or `python -m pip install --upgrade qwenpaw`

The update script will also update `modelscope` SDK and `uv` package manager.

---

## Comparison with U-Claw

| Feature | U-Claw | Q-Paw |
|---------|--------|-------|
| Base Framework | OpenClaw (Node.js) | QwenPaw / AgentScope (Python) |
| Package Manager | npm | uv (fast) + pip (fallback) |
| Portable Runtime | Node.js Embedded | Python Embedded / Miniconda |
| Model Strategy | Included by default | Not downloaded by default, on-demand |
| Security | Basic | Three-layer (tool guard / file guard / skill scanner) |

---

## Credits

- [QwenPaw](https://github.com/agentscope-ai/QwenPaw) — Open-source AI assistant by AgentScope team
- [U-Claw](https://github.com/dongsheng123132/u-claw) — USB portable solution inspiration
- [AgentScope](https://github.com/modelscope/agentscope) — Multi-agent framework
- [uv](https://github.com/astral-sh/uv) — Extremely fast Python package manager
