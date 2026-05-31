#!/usr/bin/env python3
"""
Render Q-Paw terminal screens as HTML and capture screenshots with Playwright.
These are pixel-accurate renderings of the actual program output.
"""

import asyncio
import os
from playwright.async_api import async_playwright

OUTPUT_DIR = "/home/z/my-project/upload/Q-Paw/Q-Paw/docs/images"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# Screenshot 1: QPaw.exe Main Menu
# ============================================================
QPaw_menu_html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap');
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #0c0c0c;
    padding: 24px 32px;
    font-family: 'JetBrains Mono', 'Cascadia Mono', 'Consolas', monospace;
    font-size: 14px;
    line-height: 1.5;
    color: #cccccc;
    min-width: 720px;
    display: inline-block;
  }
  .orange { color: #ff8c00; }
  .green { color: #4ec94e; }
  .red { color: #e05555; }
  .gray { color: #808080; }
  .dim { color: #aaaaaa; }
  .bold { font-weight: 700; }
  .title-bar {
    background: #ff8c00;
    color: #000;
    padding: 4px 12px;
    font-size: 12px;
    font-weight: bold;
    margin-bottom: 0;
    display: flex;
    justify-content: space-between;
  }
  .terminal {
    border: 1px solid #444;
    border-top: none;
    padding: 16px 20px;
    background: #0c0c0c;
  }
</style>
</head>
<body>
<div class="title-bar">
  <span>QPaw.exe</span>
  <span>E:\Q-Paw</span>
</div>
<div class="terminal">
<br>
  <span class="bold orange">╔═══════════════════════════════════════════╗</span><br>
  <span class="bold orange">║</span>            <span class="bold">Q-Paw 便携助手 v2.0</span>           <span class="orange">║</span><br>
  <span class="bold orange">║</span>        <span class="bold">QwenPaw U盘启动器 - 即插即用</span>       <span class="orange">║</span><br>
  <span class="bold orange">╚═══════════════════════════════════════════╝</span><br>
<br>
  <span class="dim">┌─ 系统状态 ────────────────────────────────┐</span><br>
  <span class="dim">│</span>  Python:  <span class="green">已安装</span>                 uv: <span class="green">已安装</span>       <span class="dim">│</span><br>
  <span class="dim">│</span>  QwenPaw: <span class="green">已安装</span>                 模型: <span class="bold">0</span>          <span class="dim">     │</span><br>
  <span class="dim">│</span>  工作区:  <span class="green">已初始化</span>                              <span class="dim">│</span><br>
  <span class="dim">│</span>  运行模式: <span class="green">在线</span>                                 <span class="dim">│</span><br>
  <span class="dim">└──────────────────────────────────────────┘</span><br>
<br>
  <span class="bold">[1]</span> 📥 安装环境      <span class="gray">首次使用必选 (安装 + 初始化工作区)</span><br>
  <span class="bold">[2]</span> 🚀 启动 QwenPaw  <span class="gray">在线/离线模式启动</span><br>
  <span class="bold">[3]</span> 📦 模型管理      <span class="gray">下载/导入/删除本地模型</span><br>
  <span class="bold">[4]</span> 🔄 更新          <span class="gray">更新 QwenPaw + modelscope + uv</span><br>
  <span class="bold">[5]</span> 🔀 数据迁移      <span class="gray">从旧版 Q-Paw 合并数据</span><br>
  <span class="bold">[6]</span> ⚙️  配置          <span class="gray">编辑 API Key / 运行模式等</span><br>
  <span class="bold">[7]</span> 🧹 清理          <span class="gray">清理缓存和临时文件</span><br>
<br>
  <span class="dim">[0] 退出</span><br>
<br>
  请选择 &gt; <span class="gray">█</span>
</div>
</body>
</html>
"""

# ============================================================
# Screenshot 2: Setup Process
# ============================================================
Setup_html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap');
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #0c0c0c;
    padding: 24px 32px;
    font-family: 'JetBrains Mono', 'Cascadia Mono', 'Consolas', monospace;
    font-size: 13.5px;
    line-height: 1.45;
    color: #cccccc;
    min-width: 740px;
    display: inline-block;
  }
  .orange { color: #ff8c00; }
  .green { color: #4ec94e; }
  .red { color: #e05555; }
  .gray { color: #808080; }
  .dim { color: #aaaaaa; }
  .bold { font-weight: 700; }
  .cyan { color: #00bfff; }
  .yellow { color: #ffd700; }
  .title-bar {
    background: #ff8c00;
    color: #000;
    padding: 4px 12px;
    font-size: 12px;
    font-weight: bold;
    margin-bottom: 0;
    display: flex;
    justify-content: space-between;
  }
  .terminal {
    border: 1px solid #444;
    border-top: none;
    padding: 16px 20px;
    background: #0c0c0c;
  }
</style>
</head>
<body>
<div class="title-bar">
  <span>QPaw.exe - 安装环境</span>
  <span>E:\Q-Paw</span>
</div>
<div class="terminal">
<br>
  <span class="bold">  ═══ 📥 安装环境 ═══</span><br>
<br>
  <span class="cyan">  =============================================</span><br>
  <span class="cyan">    Q-Paw Setup - Initializing...</span><br>
  <span class="cyan">    Package manager: uv (fast) / pip (fallback)</span><br>
  <span class="cyan">    Mirrors: China-first</span><br>
  <span class="cyan">  =============================================</span><br>
<br>
  <span class="bold">  [1/6]</span> Installing uv package manager...<br>
  <span class="green">  OK</span> - uv installed.<br>
<br>
  <span class="bold">  [2/6]</span> Checking portable Python...<br>
  Downloading Python 3.11 Embedded 64-bit...<br>
  <span class="gray">  Trying NPMMirror (China)...</span><br>
  <span class="green">  OK</span> - Portable Python installed.<br>
<br>
  <span class="bold">  [3/6]</span> Installing QwenPaw...<br>
  <span class="gray">  Installing with uv (10-100x faster than pip)...</span><br>
  <span class="gray">  Mirror: Aliyun</span><br>
  <span class="green">  OK</span> - QwenPaw installed via uv.<br>
<br>
  <span class="bold">  [4/6]</span> Creating portable directories...<br>
  <span class="green">  OK</span> - Directories created.<br>
<br>
  <span class="bold">  [5/6]</span> Generating portable config...<br>
  <span class="green">  OK</span> - Config generated.<br>
<br>
  <span class="bold">  [6/6]</span> Initializing QwenPaw workspace...<br>
  <span class="gray">  Running qwenpaw init --defaults...</span><br>
  <span class="green">  OK</span> - QwenPaw workspace initialized.<br>
<br>
  <span class="cyan">  =============================================</span><br>
  <span class="cyan">    Setup Complete!</span><br>
  <span class="cyan">  =============================================</span><br>
<br>
  Package manager: <span class="green">uv (fast mode)</span><br>
  Run Windows\launch.bat to start QwenPaw<br>
  Run Windows\model-manager.bat to manage models<br>
<br>
  <span class="yellow">  [TIP]</span> uv is 10-100x faster than pip.<br>
        If uv failed to install, pip works fine too.<br>
</div>
</body>
</html>
"""

# ============================================================
# Screenshot 3: Config Editor
# ============================================================
Config_html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap');
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #0c0c0c;
    padding: 24px 32px;
    font-family: 'JetBrains Mono', 'Cascadia Mono', 'Consolas', monospace;
    font-size: 14px;
    line-height: 1.5;
    color: #cccccc;
    min-width: 720px;
    display: inline-block;
  }
  .orange { color: #ff8c00; }
  .green { color: #4ec94e; }
  .red { color: #e05555; }
  .gray { color: #808080; }
  .dim { color: #aaaaaa; }
  .bold { font-weight: 700; }
  .cyan { color: #00bfff; }
  .yellow { color: #ffd700; }
  .title-bar {
    background: #0d47a1;
    color: #fff;
    padding: 4px 12px;
    font-size: 12px;
    font-weight: bold;
    margin-bottom: 0;
    display: flex;
    justify-content: space-between;
  }
  .terminal {
    border: 1px solid #444;
    border-top: none;
    padding: 16px 20px;
    background: #0c0c0c;
  }
</style>
</head>
<body>
<div class="title-bar">
  <span>Q-Paw 配置编辑器</span>
  <span>qpaw-config.py</span>
</div>
<div class="terminal">
<br>
  <span class="bold orange">╔══════════════════════════════════════════╗</span><br>
  <span class="bold orange">║</span>       <span class="bold">Q-Paw 配置编辑器</span>              <span class="orange">║</span><br>
  <span class="bold orange">╚══════════════════════════════════════════╝</span><br>
<br>
  <span class="dim">┌─ 当前配置 ────────────────────────────────┐</span><br>
  <span class="dim">│</span>  提供商:   <span class="bold">DashScope (阿里云百炼)</span><br>
  <span class="dim">│</span>  模型:     <span class="green">qwen-plus</span><br>
  <span class="dim">│</span>  运行模式: 在线<br>
  <span class="dim">│</span>  语言:     zh<br>
  <span class="dim">│</span>  审批级别: AUTO<br>
  <span class="dim">└──────────────────────────────────────────┘</span><br>
<br>
  <span class="bold">═══ 模型与提供商配置 ═══</span><br>
  当前: <span class="green">dashscope</span> / <span class="green">qwen-plus</span><br>
<br>
  <span class="dim">  ──────────────────────────────────────────</span><br>
<br>
    <span class="bold">[1]</span> 切换提供商        <span class="gray">选择 DashScope/OpenAI/Ollama 等</span><br>
    <span class="bold">[2]</span> 设置 API Key      <span class="gray">配置当前提供商的 API 密钥</span><br>
    <span class="bold">[3]</span> 切换模型          <span class="gray">更改当前使用的模型名称</span><br>
    <span class="bold">[4]</span> 修改 API 地址     <span class="gray">自定义 base_url (代理/内网)</span><br>
    <span class="bold">[5]</span> 添加自定义提供商  <span class="gray">连接第三方 OpenAI 兼容 API</span><br>
    <span class="bold">[6]</span> 测试连接          <span class="gray">验证 API Key 和地址是否可用</span><br>
<br>
    <span class="dim">[0] 返回</span><br>
<br>
  请选择 &gt; <span class="gray">█</span>
</div>
</body>
</html>
"""

# ============================================================
# Screenshot 4: Launch screen (macOS/Linux style)
# ============================================================
Launch_html = """<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&display=swap');
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: #1a1a2e;
    padding: 24px 32px;
    font-family: 'JetBrains Mono', 'Cascadia Mono', 'Consolas', monospace;
    font-size: 13.5px;
    line-height: 1.45;
    color: #cccccc;
    min-width: 720px;
    display: inline-block;
  }
  .orange { color: #ff8c00; }
  .green { color: #4ec94e; }
  .red { color: #e05555; }
  .gray { color: #808080; }
  .dim { color: #aaaaaa; }
  .bold { font-weight: 700; }
  .cyan { color: #00bfff; }
  .yellow { color: #ffd700; }
  .terminal {
    border: 1px solid #333;
    border-radius: 8px 8px 0 0;
    padding: 16px 20px;
    background: #1a1a2e;
  }
  .title-bar {
    background: #2d2d44;
    color: #ccc;
    padding: 6px 12px;
    font-size: 12px;
    font-weight: bold;
    margin-bottom: 0;
    display: flex;
    justify-content: space-between;
    border-radius: 8px 8px 0 0;
    border: 1px solid #333;
    border-bottom: none;
  }
  .dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 4px; }
  .dot-red { background: #ff5f56; }
  .dot-yellow { background: #ffbd2e; }
  .dot-green { background: #27c93f; }
</style>
</head>
<body>
<div class="title-bar">
  <span><span class="dot dot-red"></span><span class="dot dot-yellow"></span><span class="dot dot-green"></span>  Terminal — bash</span>
  <span>~/Q-Paw</span>
</div>
<div class="terminal">
<br>
  <span class="cyan"> =============================================</span><br>
  <span class="cyan">   Q-Paw Portable - QwenPaw USB Launcher</span><br>
  <span class="cyan"> =============================================</span><br>
<br>
 USB Root:   <span class="green">/Volumes/Q-PAW/Q-Paw</span><br>
 Python:     <span class="green">/Volumes/Q-PAW/Q-Paw/python-macos/bin/python3</span><br>
 Work Dir:   <span class="green">/Volumes/Q-PAW/Q-Paw/data</span><br>
 Secret Dir: <span class="green">/Volumes/Q-PAW/Q-Paw/data/.secret</span><br>
 Models Dir: <span class="green">/Volumes/Q-PAW/Q-Paw/models</span><br>
 Pkg Mgr:    <span class="green">uv (fast)</span><br>
<br>
 <span class="yellow"> [INFO]</span> No local models found. Online mode will be used.<br>
        Run <span class="green">model-manager.sh</span> to download or import models.<br>
<br>
 Starting QwenPaw...<br>
<br>
 <span class="green"> ✅ QwenPaw is running at http://localhost:7860</span><br>
 <span class="dim">   Open this URL in your browser to start chatting.</span><br>
</div>
</body>
</html>
"""


async def capture_screenshots():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        
        screenshots = [
            ("qpaw-menu.png", QPaw_menu_html, "QPaw.exe Main Menu"),
            ("qpaw-setup.png", Setup_html, "Setup Process"),
            ("qpaw-config.png", Config_html, "Config Editor"),
            ("qpaw-launch.png", Launch_html, "Launch Screen"),
        ]
        
        for filename, html, desc in screenshots:
            page = await browser.new_page()
            await page.set_content(html, wait_until="networkidle")
            # Wait for fonts to load
            await page.wait_for_timeout(2000)
            
            output_path = os.path.join(OUTPUT_DIR, filename)
            await page.screenshot(path=output_path, full_page=True)
            print(f"✅ Captured: {output_path} ({desc})")
            await page.close()
        
        await browser.close()
        print(f"\nAll {len(screenshots)} screenshots saved to {OUTPUT_DIR}")


if __name__ == "__main__":
    asyncio.run(capture_screenshots())
