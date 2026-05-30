# Q-Paw 便携版 — QwenPaw U盘启动器

> 把 QwenPaw（千问个人智能体工作台）装进U盘，即插即用，随拔即走。

---

## Q-Paw 是什么？

**Q-Paw** 参照 [U-Claw（虾盘）](https://github.com/dongsheng123132/u-claw) 的便携U盘思路，将 [QwenPaw](https://github.com/agentscope-ai/QwenPaw) 打包成U盘便携版。名字取自 **Q**wen + **Paw**（爪子），寓意千问的智识与爪子的温度——一只随身携带的"数字小爪"🐾。

### 核心特点

| 特点 | 说明 |
|------|------|
| 🖥️ **可视化向导** | .NET WinForms 图形界面 — 安装、启动、管理模型全程可视化操作 |
| 🔌 **即插即用** | 插入U盘，双击 `QPawWizard.exe` 即可开始使用 |
| 🚀 **随拔即走** | 所有配置和数据保存在U盘，拔出不留痕迹 |
| ⚡ **uv + pip** | 默认使用 uv（比 pip 快 10-100 倍），不可用时自动回退到 pip |
| 📦 **模型不默认下载** | 默认在线模式，按需下载或导入本地模型 |
| 🌐 **免翻墙** | 依赖从阿里云/清华/华为镜像源下载，无需科学上网 |
| 💻 **跨平台** | Windows（可视化+脚本）/ macOS / Linux（脚本） |
| 🛡️ **安全防护** | 继承 QwenPaw 三层安全体系（工具守卫/文件防护/技能扫描） |

---

## 快速开始

### 方式 A：可视化向导（推荐，Windows）

1. 将整个 `Q-Paw` 目录拷贝到U盘
2. 双击 **`QPawWizard.exe`** — 自包含 .NET 8 应用，无需安装 .NET 运行时
3. 按向导操作：
   - **📥 安装向导** — 一键安装 uv + Python + QwenPaw + modelscope
   - **🔌 API 配置** — 配置 DashScope / OpenAI / OpenRouter / ModelScope 的 API Key
   - **🚀 启动助手** — 在线/离线模式启动 QwenPaw
   - **📦 模型管理** — 下载 / 导入 / 删除模型
   - **⚙️ 设置** — 包管理器、镜像源、模式切换、缓存清理
   - **🔄 数据迁移** — 从旧版 Q-Paw 合并数据
   - **💻 控制台** — 实时查看命令执行输出

### 方式 B：命令行（Windows / macOS / Linux）

**Windows：**
```
双击 setup.bat            → 安装环境
双击 launch.bat           → 启动 QwenPaw
双击 model-manager.bat    → 管理模型
```

**macOS / Linux：**
```bash
chmod +x setup.sh && ./setup.sh     # 安装
./launch.sh                          # 启动
./model-manager.sh                   # 管理模型
```

初始化脚本会自动完成以下操作：

1. **安装 uv 包管理器**（从 NPMMirror / GitHub 下载）
2. **下载便携 Python 环境**
   - Windows：Python 3.11 Embedded（轻量版，约 15MB）
   - macOS/Linux：Miniconda（自动适配架构）
3. **安装 QwenPaw + modelscope**（uv 优先，pip 兜底；使用国内镜像源）
4. **创建便携目录结构**（data / config / models / logs）
5. **生成便携模式配置文件**（`config/portable.env`）

> 安装过程需要联网。首次安装约需 2-10 分钟（uv 模式）或 5-15 分钟（pip 模式），取决于网速。

---

## 目录结构

```
Q-Paw/                          ← U盘根目录
├── QPawWizard.exe              # 🖥️ 可视化向导（自包含 .NET 8，69MB）
├── index.html                  # 网页控制台（浏览器打开）
│
├── launch.bat / .sh            # 启动脚本
├── setup.bat / .sh             # 初始化安装脚本
├── model-manager.bat / .sh     # 模型管理器
├── migrate.bat / .sh           # 迁移工具
├── cleanup.bat                 # 清理工具
├── update.bat / .sh            # 更新脚本（更新 uv + QwenPaw + modelscope）
│
├── bin/                        # uv.exe + 其他二进制
├── python/                     # Windows 便携 Python (Embedded)
├── python-macos/               # macOS 便携 Python (Miniconda)
├── python-linux/               # Linux 便携 Python (Miniconda)
│
├── models/                     # 本地模型目录（按需下载，默认为空）
├── config/                     # 配置文件
│   ├── portable.env            # 便携模式环境变量（自动生成）
│   ├── api-keys.env            # API 密钥（向导生成）
│   ├── qwenpaw-config.yaml    # QwenPaw 配置（向导生成）
│   └── *.example               # 配置示例
├── data/                       # 用户数据（QWENPAW_WORKING_DIR）
├── logs/                       # 日志文件
├── scripts/                    # 辅助脚本
├── README.md                   # 英文文档
└── README_zh.md                # 中文文档（本文件）
```

---

## QPawWizard.exe — 可视化向导

`QPawWizard.exe` 是一个自包含的 .NET 8 WinForms 应用程序，提供所有 Q-Paw 操作的图形界面。**无需在目标电脑上安装 .NET 运行时**。

### 功能页面

| 页面 | 功能 |
|------|------|
| 🏠 **仪表盘** | 系统状态概览 — Python、QwenPaw、模型数量、包管理器、磁盘空间 |
| 📥 **安装向导** | 一键安装：uv → Python → QwenPaw → modelscope → 配置 |
| 🚀 **启动助手** | 在线/离线模式启动 QwenPaw，自动设置环境变量 |
| 📦 **模型管理** | 从 ModelScope 下载模型、导入本地模型、删除模型 |
| 🔄 **更新 QwenPaw** | 一键更新 uv + QwenPaw + modelscope（也可用 `update.bat` / `update.sh`） |
| 🔌 **API 配置** | DashScope / OpenAI / OpenRouter / ModelScope API Key 管理，一键测试连通性 |
| ⚙️ **设置** | 包管理器选择、下载镜像源、模型模式、缓存清理 |
| 🔄 **数据迁移** | 从旧版 Q-Paw 目录合并模型 + 数据 + 配置 |
| 💻 **控制台** | 实时命令执行输出，查看安装/下载/测试日志 |

### 技术细节

- **框架**：.NET 8 WinForms（C#）
- **发布**：自包含单文件，`win-x64`，压缩
- **大小**：约 69MB（包含 .NET 运行时，无需单独安装）
- **源码**：`Q-Paw-App/QPawWizard/` 目录
- **重新构建**：运行 `build.bat`（Windows）或 `build.sh`（Linux/macOS 交叉编译）

---

## 两种运行模式

| 模式 | 需要网络 | 需要本地模型 | 说明 |
|------|---------|-------------|------|
| **在线模式**（默认） | ✅ | ❌ | 调用云端 API（DashScope / OpenAI / OpenRouter / ModelScope），响应快、效果好 |
| **离线模式** | ❌ | ✅ | 使用本地模型推理，完全离线运行，数据不出U盘 |

切换方式：
- 通过 QPawWizard.exe → ⚙️ 设置 切换
- 通过 `model-manager` 脚本一键切换
- 或手动编辑 `config/portable.env` 中的 `QP_MODEL_MODE=online` / `local`

### API 提供商

| 提供商 | 类型 | 特点 |
|--------|------|------|
| 🔵 **DashScope** | 云端 API | 通义千问官方 API，国内直连，新用户免费额度 |
| 🟢 **OpenAI** | 云端 API | GPT-4o 等，支持代理 |
| 🟣 **OpenRouter** | 云端 API | 100+ 模型，统一 API，部分免费 |
| 🟣 **ModelScope** | 云端 API + 本地 | 每日2000次免费调用，国内直连，支持本地下载 |

### 离线模式推荐模型

| 模型 | 大小 | 说明 |
|------|------|------|
| **QwenPaw-Flash-2B**（推荐） | ~4GB | 专为 QwenPaw Agent 场景优化 |
| Qwen2.5-3B-Instruct | ~6GB | 平衡选择 |
| Qwen2.5-7B-Instruct | ~15GB | 效果最好，需较大U盘 |

---

## 包管理：uv + pip 双支持

Q-Paw 默认使用 **uv** 作为包管理器，同时支持 **pip** 作为回退方案：

| 组件 | 包管理 | 镜像源 |
|------|--------|--------|
| uv 二进制 | — | NPMMirror / GitHub |
| Python Embedded | — | NPMMirror / 华为云 / python.org |
| Miniconda | — | 清华 TUNA / 官方 |
| QwenPaw 等包 | **uv 优先**，pip 兜底 | 阿里云 / 清华 / 华为 / 官方 |
| ModelScope 模型 | — | 魔搭（国内直连） |

---

## 推荐U盘规格

| 项目 | 最低要求 | 推荐配置 |
|------|---------|---------|
| 容量 | 8GB（不含模型） | 32GB+（含本地模型） |
| 接口 | USB 2.0 | USB 3.0+（大幅提升模型加载速度） |
| 格式 | FAT32 / exFAT | exFAT（支持大于 4GB 的文件） |

> 💡 如果只使用在线模式，8GB U盘就够了。如需离线模型，建议 32GB 以上的 USB 3.0 U盘。

---

## 安全特性

Q-Paw 继承 QwenPaw 的三层安全防护体系：

1. **工具守卫（Tool Guard）**— 拦截危险命令执行
2. **文件防护（File Guard）**— 限制文件访问范围到U盘
3. **技能扫描器（Skill Scanner）**— 安装技能前安全检查

---

## 常见问题

### Q：QPawWizard.exe 有 69MB，需要安装 .NET 吗？
不需要！它是自包含单文件可执行程序，内置了 .NET 运行时。双击即可运行，无需额外安装。

### Q：插上U盘就能直接用吗？
需要先运行一次安装（通过 QPawWizard.exe 或 setup.bat）完成初始化。之后每次插入U盘双击启动即可。

### Q：不用本地模型可以吗？
完全可以！默认就是在线模式，通过云端 API 使用 AI，不需要下载任何模型。

### Q：如何升级 Q-Paw 且不丢失数据？
使用 QPawWizard.exe → 🔄 数据迁移，或运行 `migrate.bat` / `migrate.sh`。

### Q：如何更新 QwenPaw 到最新版本？
三种方式更新：
1. **QPawWizard.exe** → 点击仪表盘或启动页的「🔄 更新 QwenPaw」按钮
2. **脚本**：双击 `update.bat`（Windows）或运行 `./update.sh`（macOS/Linux）
3. **手动**：运行 `uv pip install --upgrade qwenpaw` 或 `python -m pip install --upgrade qwenpaw`

更新脚本会同时更新 `modelscope` SDK 和 `uv` 包管理器。

### Q：setup 运行中断了怎么办？
直接重新运行即可。脚本会自动检测已安装的组件并跳过。

---

## 与 U-Claw 的对比

| 对比项 | U-Claw（虾盘） | Q-Paw |
|--------|----------------|-------|
| 底层框架 | OpenClaw（Node.js） | QwenPaw / AgentScope（Python） |
| 可视化向导 | 无 | .NET WinForms 图形向导 |
| 包管理 | npm | uv（快10-100倍）+ pip（兼容） |
| 便携运行时 | Node.js Embedded | Python Embedded / Miniconda |
| 模型策略 | 默认包含 | 不默认下载，用户按需操作 |
| 安全防护 | 基础 | 三层防护体系 |

---

## 致谢

- [QwenPaw](https://github.com/agentscope-ai/QwenPaw) — AgentScope 团队开源的 AI 助手框架
- [U-Claw（虾盘）](https://github.com/dongsheng123132/u-claw) — 便携U盘方案灵感来源
- [AgentScope](https://github.com/modelscope/agentscope) — 多智能体框架
- [uv](https://github.com/astral-sh/uv) — 极速 Python 包管理器
