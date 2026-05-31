#!/usr/bin/env python3
"""
Q-Paw Interactive Configuration Editor
=======================================
Directly modifies QwenPaw's config.json and provider files.
All changes are written to disk immediately.

Key architecture:
  - data/config.json          -> main config (agents, channels, security, etc.)
  - data/.secret/providers/   -> LLM provider configs (with encrypted API keys)
  - data/.secret/providers/active_model.json -> active provider + model
"""

import json
import os
import sys
import shutil
from pathlib import Path
from datetime import datetime

# --- Resolve paths ---

def resolve_usb_root():
    """Find USB root from script location or environment."""
    env = os.environ.get('USB_ROOT')
    if env:
        return Path(env)
    script = Path(__file__).resolve()
    parent = script.parent
    if parent.name == 'scripts':
        return parent.parent
    return parent

USB_ROOT = resolve_usb_root()
WORKING_DIR = Path(os.environ.get('QWENPAW_WORKING_DIR', str(USB_ROOT / 'data')))
SECRET_DIR = Path(os.environ.get('QWENPAW_SECRET_DIR', str(WORKING_DIR / '.secret')))
CONFIG_JSON = WORKING_DIR / 'config.json'
ACTIVE_MODEL_JSON = SECRET_DIR / 'providers' / 'active_model.json'
PROVIDERS_DIR = SECRET_DIR / 'providers' / 'builtin'
CUSTOM_PROVIDERS_DIR = SECRET_DIR / 'providers' / 'custom'

# --- Built-in provider definitions ---

BUILTIN_PROVIDERS = {
    "dashscope": {
        "name": "DashScope (\u963f\u91cc\u4e91\u767e\u70bc)",
        "base_url": "https://dashscope.aliyuncs.com/compatible-mode/v1",
        "is_local": False,
        "default_model": "qwen-plus",
        "models": ["qwen-plus", "qwen-turbo", "qwen-max", "qwen3-max", "qwen3-plus", "qwen3-turbo"],
        "api_key_url": "https://dashscope.console.aliyun.com/",
    },
    "openai": {
        "name": "OpenAI",
        "base_url": "https://api.openai.com/v1",
        "is_local": False,
        "default_model": "gpt-4o",
        "models": ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "o1", "o1-mini", "o3-mini"],
        "api_key_url": "https://platform.openai.com/api-keys",
    },
    "openrouter": {
        "name": "OpenRouter",
        "base_url": "https://openrouter.ai/api/v1",
        "is_local": False,
        "default_model": "openai/gpt-4o",
        "models": ["openai/gpt-4o", "openai/gpt-4o-mini", "anthropic/claude-3.5-sonnet", "google/gemini-pro", "meta-llama/llama-3-70b-instruct"],
        "api_key_url": "https://openrouter.ai/keys",
    },
    "modelscope": {
        "name": "ModelScope (\u9b54\u642d)",
        "base_url": "https://api-inference.modelscope.cn/v1",
        "is_local": False,
        "default_model": "qwen-plus",
        "models": ["qwen-plus", "qwen-turbo", "qwen-max"],
        "api_key_url": "https://modelscope.cn/my/myaccesstoken",
    },
    "anthropic": {
        "name": "Anthropic (Claude)",
        "base_url": "https://api.anthropic.com/v1",
        "is_local": False,
        "default_model": "claude-sonnet-4-20250514",
        "models": ["claude-sonnet-4-20250514", "claude-3-5-sonnet-20241022", "claude-3-haiku-20240307"],
        "api_key_url": "https://console.anthropic.com/settings/keys",
    },
    "gemini": {
        "name": "Google Gemini",
        "base_url": "https://generativelanguage.googleapis.com/v1beta/openai",
        "is_local": False,
        "default_model": "gemini-2.0-flash",
        "models": ["gemini-2.0-flash", "gemini-1.5-pro", "gemini-1.5-flash"],
        "api_key_url": "https://aistudio.google.com/apikey",
    },
    "zhipu": {
        "name": "\u667a\u8bafAI (GLM)",
        "base_url": "https://open.bigmodel.cn/api/paas/v4",
        "is_local": False,
        "default_model": "glm-4-plus",
        "models": ["glm-4-plus", "glm-4-flash", "glm-4-air", "glm-4-long"],
        "api_key_url": "https://open.bigmodel.cn/usercenter/apikeys",
    },
    "ollama": {
        "name": "Ollama (\u672c\u5730)",
        "base_url": "http://localhost:11434/v1",
        "is_local": True,
        "default_model": "qwen2.5:7b",
        "models": ["qwen2.5:7b", "qwen2.5:14b", "llama3:8b", "gemma2:9b"],
        "api_key_url": "",
    },
    "lmstudio": {
        "name": "LM Studio (\u672c\u5730)",
        "base_url": "http://localhost:1234/v1",
        "is_local": True,
        "default_model": "default",
        "models": ["default"],
        "api_key_url": "",
    },
}

# --- JSON helpers ---

def load_json(path, default=None):
    """Load JSON file, return default if not found or corrupt."""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default if default is not None else {}

def save_json(path, data):
    """Save JSON file with pretty print and auto-backup."""
    path.parent.mkdir(parents=True, exist_ok=True)
    # Backup first
    if path.exists():
        backup = path.with_suffix(f'.json.bak.{datetime.now().strftime("%Y%m%d_%H%M%S")}')
        shutil.copy2(path, backup)
        # Keep only last 3 backups
        backups = sorted(path.parent.glob(f'{path.stem}.json.bak.*'))
        for old in backups[:-3]:
            old.unlink(missing_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

def get_nested(data, keys, default=None):
    """Get nested dict value."""
    for key in keys:
        if isinstance(data, dict) and key in data:
            data = data[key]
        else:
            return default
    return data

def set_nested(data, keys, value):
    """Set nested dict value, creating intermediate dicts as needed."""
    for key in keys[:-1]:
        if key not in data or not isinstance(data[key], dict):
            data[key] = {}
        data = data[key]
    data[keys[-1]] = value

# --- ANSI colors ---

class C:
    R = '\033[0m'
    B = '\033[1m'
    D = '\033[2m'
    ORG = '\033[38;5;208m'
    GRN = '\033[32m'
    RED = '\033[31m'
    YEL = '\033[33m'
    CYN = '\033[36m'
    GR = '\033[90m'

def enable_vtp():
    """Enable Virtual Terminal Processing on Windows."""
    if sys.platform != 'win32':
        return
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        handle = kernel32.GetStdHandle(-11)
        mode = ctypes.c_ulong()
        kernel32.GetConsoleMode(handle, ctypes.byref(mode))
        kernel32.SetConsoleMode(handle, mode.value | 0x0007)
    except Exception:
        pass

def clear():
    os.system('cls' if sys.platform == 'win32' else 'clear')

# --- Input helpers ---

def prompt(text, default=''):
    """Prompt for input with optional default."""
    if default:
        display = f'{C.D}({default}){C.R}'
        result = input(f'  {text} {display}: ').strip()
        return result if result else default
    return input(f'  {text}: ').strip()

def confirm(text, default=False):
    """Yes/No confirmation."""
    hint = 'Y/n' if default else 'y/N'
    result = input(f'  {text} ({hint}): ').strip().lower()
    if not result:
        return default
    return result in ('y', 'yes')

def pause(msg='\u6309\u56de\u8f66\u7ee7\u7eed...'):
    input(f'\n  {C.D}{msg}{C.R}')

def choice_menu(items, title='', allow_back=True):
    """Display a numbered choice menu, return selected index or -1 for back."""
    if title:
        print(f'\n  {C.B}{title}{C.R}')
        print(f'  {"─" * 40}')
    print()
    for i, item in enumerate(items, 1):
        print(f'    {C.B}[{i}]{C.R} {item}')
    if allow_back:
        print(f'    {C.D}[0] \u8fd4\u56de{C.R}')
    print()
    raw = input('  \u8bf7\u9009\u62e9 > ').strip()
    try:
        n = int(raw)
        if allow_back and n == 0:
            return -1
        if 1 <= n <= len(items):
            return n - 1
    except ValueError:
        pass
    return -2

# --- Provider helpers ---

def get_active_model():
    """Get current active model config."""
    return load_json(ACTIVE_MODEL_JSON, {"provider_id": "", "model": ""})

def get_provider_config(provider_id):
    """Load a provider config from .secret/providers/."""
    p = PROVIDERS_DIR / f'{provider_id}.json'
    if not p.exists():
        p = CUSTOM_PROVIDERS_DIR / f'{provider_id}.json'
    if p.exists():
        return load_json(p)
    return None

def save_provider_config(provider_id, config):
    """Save provider config to builtin/ or custom/."""
    is_custom = config.get('is_custom', False)
    d = CUSTOM_PROVIDERS_DIR if is_custom else PROVIDERS_DIR
    save_json(d / f'{provider_id}.json', config)

def set_active_model(provider_id, model):
    """Set the active model selection."""
    save_json(ACTIVE_MODEL_JSON, {"provider_id": provider_id, "model": model})

# --- Banner ---

def show_banner():
    print()
    print(f'  {C.B}{C.ORG}\u2554\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2557{C.R}')
    print(f'  {C.B}{C.ORG}\u2551{C.R}       {C.B}Q-Paw \u914d\u7f6e\u7f16\u8f91\u5668{C.R}              {C.ORG}\u2551{C.R}')
    print(f'  {C.B}{C.ORG}\u255a\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u255d{C.R}')

def show_current_status():
    """Display current configuration status."""
    active = get_active_model()
    provider_id = active.get('provider_id', '')
    model = active.get('model', '')

    provider_info = BUILTIN_PROVIDERS.get(provider_id, {})
    provider_name = provider_info.get('name', provider_id) if provider_id else C.RED + '\u672a\u914d\u7f6e' + C.R

    config = load_json(CONFIG_JSON)
    language = get_nested(config, ['agents', 'language'], 'zh')
    approval = get_nested(config, ['agents', 'running', 'approval_level'], 'AUTO')

    mode = '\u5728\u7ebf'
    env_path = USB_ROOT / 'config' / 'portable.env'
    if env_path.exists():
        content = env_path.read_text(encoding='utf-8')
        if 'QP_MODEL_MODE=local' in content:
            mode = '\u79bb\u7ebf'

    print(f'\n  {C.D}\u250c\u2500 \u5f53\u524d\u914d\u7f6e \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2510{C.R}')
    print(f'  {C.D}\u2502{C.R}  \u63d0\u4f9b\u5546:   {C.B}{provider_name}{C.R}')
    print(f'  {C.D}\u2502{C.R}  \u6a21\u578b:     {C.GRN}{model or "\u672a\u914d\u7f6e"}{C.R}')
    print(f'  {C.D}\u2502{C.R}  \u8fd0\u884c\u6a21\u5f0f: {mode}')
    print(f'  {C.D}\u2502{C.R}  \u8bed\u8a00:     {language}')
    print(f'  {C.D}\u2502{C.R}  \u5ba1\u6279\u7ea7\u522b: {approval}')
    print(f'  {C.D}\u2514\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2518{C.R}')

# --- Section 1: Model & Provider ---

def section_model_provider():
    """Configure LLM provider, model, API key, and base URL."""
    while True:
        clear()
        show_banner()

        active = get_active_model()
        current_pid = active.get('provider_id', '')
        current_model = active.get('model', '')

        print(f'\n  {C.B}\u2550\u2550\u2550 \u6a21\u578b\u4e0e\u63d0\u4f9b\u5546\u914d\u7f6e \u2550\u2550\u2550{C.R}')
        print(f'  \u5f53\u524d: {C.GRN}{current_pid}{C.R} / {C.GRN}{current_model}{C.R}')

        items = [
            f'\u5207\u6362\u63d0\u4f9b\u5546        {C.GR}\u9009\u62e9 DashScope/OpenAI/Ollama \u7b49{C.R}',
            f'\u8bbe\u7f6e API Key      {C.GR}\u914d\u7f6e\u5f53\u524d\u63d0\u4f9b\u5546\u7684 API \u5bc6\u94a5{C.R}',
            f'\u5207\u6362\u6a21\u578b          {C.GR}\u66f4\u6539\u5f53\u524d\u4f7f\u7528\u7684\u6a21\u578b\u540d\u79f0{C.R}',
            f'\u4fee\u6539 API \u5730\u5740     {C.GR}\u81ea\u5b9a\u4e49 base_url (\u4ee3\u7406/\u5185\u7f51){C.R}',
            f'\u6dfb\u52a0\u81ea\u5b9a\u4e49\u63d0\u4f9b\u5546  {C.GR}\u8fde\u63a5\u7b2c\u4e09\u65b9 OpenAI \u517c\u5bb9 API{C.R}',
            f'\u6d4b\u8bd5\u8fde\u63a5          {C.GR}\u9a8c\u8bc1 API Key \u548c\u5730\u5740\u662f\u5426\u53ef\u7528{C.R}',
        ]
        idx = choice_menu(items, '\u6a21\u578b\u4e0e\u63d0\u4f9b\u5546')
        if idx == -1:
            return
        elif idx == 0:
            action_switch_provider()
        elif idx == 1:
            action_set_api_key()
        elif idx == 2:
            action_switch_model()
        elif idx == 3:
            action_set_base_url()
        elif idx == 4:
            action_add_custom_provider()
        elif idx == 5:
            action_test_connection()

def action_switch_provider():
    """Switch to a different LLM provider."""
    print(f'\n  {C.B}\u9009\u62e9\u63d0\u4f9b\u5546:{C.R}\n')

    items = []
    provider_ids = list(BUILTIN_PROVIDERS.keys())
    for pid in provider_ids:
        info = BUILTIN_PROVIDERS[pid]
        tag = f'{C.CYN}[\u672c\u5730]{C.R}' if info['is_local'] else f'{C.ORG}[\u4e91\u7aef]{C.R}'
        items.append(f'{info["name"]:24s} {tag}  {C.GR}{pid}{C.R}')

    # Custom providers
    if CUSTOM_PROVIDERS_DIR.exists():
        for f in CUSTOM_PROVIDERS_DIR.glob('*.json'):
            pdata = load_json(f)
            pid = pdata.get('id', f.stem)
            name = pdata.get('name', pid)
            items.append(f'{name:24s} {C.YEL}[\u81ea\u5b9a\u4e49]{C.R}  {C.GR}{pid}{C.R}')
            provider_ids.append(pid)

    idx = choice_menu(items, '\u53ef\u7528\u63d0\u4f9b\u5546')
    if idx < 0:
        return

    provider_id = provider_ids[idx]
    info = BUILTIN_PROVIDERS.get(provider_id, {})

    default_model = info.get('default_model', '')
    model = prompt(f'\u6a21\u578b\u540d\u79f0', default_model)

    set_active_model(provider_id, model)

    # Ensure provider config file exists
    pconfig = get_provider_config(provider_id)
    if pconfig is None and provider_id in BUILTIN_PROVIDERS:
        pconfig = {
            "id": provider_id,
            "name": info["name"],
            "base_url": info["base_url"],
            "api_key": "",
            "chat_model": "OpenAIChatModel",
            "models": [{"id": m, "name": m} for m in info.get("models", [])],
            "extra_models": [],
            "is_local": info.get("is_local", False),
            "is_custom": False,
            "require_api_key": not info.get("is_local", False),
            "support_model_discovery": True,
        }
        save_provider_config(provider_id, pconfig)

    print(f'\n  {C.GRN}\u2705 \u5df2\u5207\u6362\u5230: {info.get("name", provider_id)} / {model}{C.R}')
    pause()

def action_set_api_key():
    """Set API key for current provider."""
    active = get_active_model()
    provider_id = active.get('provider_id', '')

    if not provider_id:
        print(f'\n  {C.RED}[\u21a9] \u8bf7\u5148\u9009\u62e9\u4e00\u4e2a\u63d0\u4f9b\u5546{C.R}')
        pause()
        return

    info = BUILTIN_PROVIDERS.get(provider_id, {})
    key_url = info.get('api_key_url', '')

    print(f'\n  {C.B}\u8bbe\u7f6e API Key \u2014 {info.get("name", provider_id)}{C.R}')
    if key_url:
        print(f'  {C.GR}\u83b7\u53d6\u5730\u5740: {key_url}{C.R}')

    pconfig = get_provider_config(provider_id)
    current_key = ''
    if pconfig:
        current_key = pconfig.get('api_key', '')

    if current_key:
        masked = current_key[:6] + '****' + current_key[-4:] if len(current_key) > 12 else '****'
        print(f'  \u5f53\u524d: {masked}')

    api_key = prompt('API Key (\u7559\u7a7a\u4fdd\u6301\u4e0d\u53d8)')
    if not api_key:
        print(f'  {C.GR}\u672a\u4fee\u6539{C.R}')
        pause()
        return

    if pconfig is None:
        pconfig = {
            "id": provider_id,
            "name": info.get("name", provider_id),
            "base_url": info.get("base_url", ""),
            "chat_model": "OpenAIChatModel",
        }
    pconfig['api_key'] = api_key
    save_provider_config(provider_id, pconfig)

    print(f'\n  {C.GRN}\u2705 API Key \u5df2\u4fdd\u5b58\u5230:{C.R}')
    print(f'     {PROVIDERS_DIR / f"{provider_id}.json"}')
    print(f'  {C.GR}\u6ce8\u610f: QwenPaw \u542f\u52a8\u65f6\u4f1a\u81ea\u52a8\u52a0\u5bc6\u5b58\u50a8\u5bc6\u94a5{C.R}')
    pause()

def action_switch_model():
    """Switch model for current provider."""
    active = get_active_model()
    provider_id = active.get('provider_id', '')
    current_model = active.get('model', '')

    if not provider_id:
        print(f'\n  {C.RED}[\u21a9] \u8bf7\u5148\u9009\u62e9\u4e00\u4e2a\u63d0\u4f9b\u5546{C.R}')
        pause()
        return

    info = BUILTIN_PROVIDERS.get(provider_id, {})
    models = info.get('models', [])

    print(f'\n  {C.B}\u9009\u62e9\u6a21\u578b \u2014 {info.get("name", provider_id)}{C.R}')
    print(f'  \u5f53\u524d: {C.GRN}{current_model}{C.R}\n')

    if models:
        for i, m in enumerate(models, 1):
            marker = ' \u2190 \u5f53\u524d' if m == current_model else ''
            print(f'    {C.B}[{i}]{C.R} {m}{C.GR}{marker}{C.R}')
        print(f'    {C.B}[0]{C.R} \u624b\u52a8\u8f93\u5165')
        print()
        raw = input('  \u8bf7\u9009\u62e9 > ').strip()
        try:
            n = int(raw)
            if 1 <= n <= len(models):
                model = models[n - 1]
                set_active_model(provider_id, model)
                print(f'\n  {C.GRN}\u2705 \u5df2\u5207\u6362\u5230: {model}{C.R}')
                pause()
                return
        except ValueError:
            pass

    model = prompt('\u6a21\u578b\u540d\u79f0')
    if model:
        set_active_model(provider_id, model)
        print(f'\n  {C.GRN}\u2705 \u5df2\u5207\u6362\u5230: {model}{C.R}')
    pause()

def action_set_base_url():
    """Modify API base URL for current provider."""
    active = get_active_model()
    provider_id = active.get('provider_id', '')

    if not provider_id:
        print(f'\n  {C.RED}[\u21a9] \u8bf7\u5148\u9009\u62e9\u4e00\u4e2a\u63d0\u4f9b\u5546{C.R}')
        pause()
        return

    info = BUILTIN_PROVIDERS.get(provider_id, {})
    pconfig = get_provider_config(provider_id)
    current_url = pconfig.get('base_url', '') if pconfig else info.get('base_url', '')

    print(f'\n  {C.B}\u4fee\u6539 API \u5730\u5740 \u2014 {info.get("name", provider_id)}{C.R}')
    print(f'  \u5f53\u524d: {C.CYN}{current_url}{C.R}')
    print(f'  {C.GR}\u9002\u7528\u4e8e: \u8bbe\u7f6e\u4ee3\u7406\u3001\u5185\u7f51\u8f6c\u53d1\u3001\u7b2c\u4e09\u65b9\u517c\u5bb9API{C.R}\n')

    new_url = prompt('\u65b0\u7684 API \u5730\u5740', current_url)
    if new_url == current_url:
        print(f'  {C.GR}\u672a\u4fee\u6539{C.R}')
        pause()
        return

    if pconfig is None:
        pconfig = {
            "id": provider_id,
            "name": info.get("name", provider_id),
            "api_key": "",
            "chat_model": "OpenAIChatModel",
            "models": [],
            "is_custom": False,
        }
    pconfig['base_url'] = new_url
    pconfig['freeze_url'] = False
    save_provider_config(provider_id, pconfig)

    print(f'\n  {C.GRN}\u2705 API \u5730\u5740\u5df2\u66f4\u65b0: {new_url}{C.R}')
    pause()

def action_add_custom_provider():
    """Add a custom OpenAI-compatible provider."""
    print(f'\n  {C.B}\u6dfb\u52a0\u81ea\u5b9a\u4e49\u63d0\u4f9b\u5546{C.R}')
    print(f'  {C.GR}\u652f\u6301\u4efb\u4f55 OpenAI \u517c\u5bb9 API (DeepSeek\u3001\u7845\u57fa\u6d41\u52a8\u3001\u4e2d\u8f6c\u7ad9\u7b49){C.R}\n')

    provider_id = prompt('\u63d0\u4f9b\u5546 ID (\u82f1\u6587, \u5982 deepseek, siliconflow)')
    if not provider_id:
        return

    name = prompt('\u663e\u793a\u540d\u79f0 (\u5982 DeepSeek)', provider_id)
    base_url = prompt('API \u5730\u5740 (\u5982 https://api.deepseek.com/v1)')
    if not base_url:
        return

    model = prompt('\u9ed8\u8ba4\u6a21\u578b (\u5982 deepseek-chat)')
    api_key = prompt('API Key (\u53ef\u7559\u7a7a\u7a0d\u540e\u914d\u7f6e)')

    config = {
        "id": provider_id,
        "name": name,
        "base_url": base_url,
        "api_key": api_key,
        "chat_model": "OpenAIChatModel",
        "models": [{"id": model, "name": model}] if model else [],
        "extra_models": [],
        "is_local": False,
        "is_custom": True,
        "require_api_key": bool(api_key),
        "support_model_discovery": False,
        "freeze_url": False,
    }

    CUSTOM_PROVIDERS_DIR.mkdir(parents=True, exist_ok=True)
    save_json(CUSTOM_PROVIDERS_DIR / f'{provider_id}.json', config)

    if confirm(f'\u662f\u5426\u5207\u6362\u5230 {name}?', default=True):
        set_active_model(provider_id, model or 'default')

    print(f'\n  {C.GRN}\u2705 \u81ea\u5b9a\u4e49\u63d0\u4f9b\u5546\u5df2\u6dfb\u52a0: {name}{C.R}')
    pause()

def action_test_connection():
    """Test API connection for current provider."""
    active = get_active_model()
    provider_id = active.get('provider_id', '')

    if not provider_id:
        print(f'\n  {C.RED}[\u21a9] \u8bf7\u5148\u9009\u62e9\u4e00\u4e2a\u63d0\u4f9b\u5546{C.R}')
        pause()
        return

    pconfig = get_provider_config(provider_id)
    base_url = pconfig.get('base_url', '') if pconfig else ''
    api_key = pconfig.get('api_key', '') if pconfig else ''

    if not base_url:
        info = BUILTIN_PROVIDERS.get(provider_id, {})
        base_url = info.get('base_url', '')

    print(f'\n  {C.B}\u6d4b\u8bd5\u8fde\u63a5 \u2014 {provider_id}{C.R}')
    print(f'  URL: {base_url}')
    print(f'\n  \u6b63\u5728\u8fde\u63a5...')

    try:
        import urllib.request
        import urllib.error

        test_url = base_url.rstrip('/') + '/models'
        headers = {}
        if api_key:
            headers['Authorization'] = f'Bearer {api_key}'

        req = urllib.request.Request(test_url, headers=headers, method='GET')
        with urllib.request.urlopen(req, timeout=10) as resp:
            status = resp.status
            body = resp.read().decode('utf-8', errors='replace')[:500]
            print(f'  {C.GRN}\u2705 \u8fde\u63a5\u6210\u529f! HTTP {status}{C.R}')
            try:
                data = json.loads(body)
                if 'data' in data:
                    available = [m.get('id', '?') for m in data['data'][:5]]
                    print(f'  \u53ef\u7528\u6a21\u578b (\u524d5): {", ".join(available)}')
            except Exception:
                pass
    except urllib.error.HTTPError as e:
        if e.code == 401:
            print(f'  {C.RED}\u274c \u8ba4\u8bc1\u5931\u8d25 \u2014 API Key \u65e0\u6548\u6216\u5df2\u8fc7\u671f{C.R}')
        elif e.code == 403:
            print(f'  {C.RED}\u274c \u8bbf\u95ee\u88ab\u62d2\u7edd \u2014 \u6743\u9650\u4e0d\u8db3{C.R}')
        elif e.code == 404:
            print(f'  {C.YEL}\u26a0\ufe0f  /models \u7aef\u70b9\u4e0d\u5b58\u5728\uff0c\u4f46\u63d0\u4f9b\u5546\u53ef\u80fd\u4ecd\u7136\u53ef\u7528{C.R}')
        else:
            print(f'  {C.RED}\u274c HTTP \u9519\u8bef: {e.code} {e.reason}{C.R}')
    except Exception as e:
        print(f'  {C.RED}\u274c \u8fde\u63a5\u5931\u8d25: {e}{C.R}')
        print(f'  {C.GR}\u63d0\u793a: \u8bf7\u68c0\u67e5\u7f51\u7edc\u548c API \u5730\u5740{C.R}')

    pause()

# --- Section 2: Agent Settings ---

def section_agent():
    """Configure agent settings: language, approval, runtime."""
    config = load_json(CONFIG_JSON)
    if not config:
        print(f'\n  {C.RED}[\u21a9] config.json \u4e0d\u5b58\u5728\uff0c\u8bf7\u5148\u8fd0\u884c setup{C.R}')
        pause()
        return

    while True:
        clear()
        show_banner()

        lang = get_nested(config, ['agents', 'language'], 'zh')
        approval = get_nested(config, ['agents', 'running', 'approval_level'], 'AUTO')
        max_iters = get_nested(config, ['agents', 'running', 'max_iters'], 100)
        max_input = get_nested(config, ['agents', 'running', 'max_input_length'], 131072)
        cmd_timeout = get_nested(config, ['agents', 'running', 'shell_command_timeout'], 60)

        print(f'\n  {C.B}\u2550\u2550\u2550 Agent \u914d\u7f6e \u2550\u2550\u2550{C.R}')
        print(f'  \u8bed\u8a00: {lang}  \u5ba1\u6279: {approval}  \u8fed\u4ee3\u4e0a\u9650: {max_iters}')
        print(f'  \u8f93\u5165\u4e0a\u9650: {max_input}  \u547d\u4ee4\u8d85\u65f6: {cmd_timeout}s')

        items = [
            f'\u8bed\u8a00              {C.GR}\u5f53\u524d: {lang} (zh/en/ru){C.R}',
            f'\u5ba1\u6279\u7ea7\u522b          {C.GR}\u5f53\u524d: {approval} (STRICT/SMART/AUTO/OFF){C.R}',
            f'\u6700\u5927\u63a8\u7406\u8fed\u4ee3      {C.GR}\u5f53\u524d: {max_iters}{C.R}',
            f'\u4e0a\u4e0b\u6587\u957f\u5ea6        {C.GR}\u5f53\u524d: {max_input}{C.R}',
            f'Shell \u547d\u4ee4\u8d85\u65f6    {C.GR}\u5f53\u524d: {cmd_timeout}s{C.R}',
        ]
        idx = choice_menu(items, 'Agent \u8bbe\u7f6e')
        if idx == -1:
            break
        elif idx == 0:
            new = prompt('\u8bed\u8a00 (zh/en/ru)', lang)
            set_nested(config, ['agents', 'language'], new)
            save_json(CONFIG_JSON, config)
            print(f'\n  {C.GRN}\u2705 \u8bed\u8a00\u5df2\u8bbe\u4e3a: {new}{C.R}')
            pause()
        elif idx == 1:
            print(f'\n  {C.GR}STRICT = \u6bcf\u6b21\u5de5\u5177\u8c03\u7528\u90fd\u9700\u786e\u8ba4{C.R}')
            print(f'  {C.GR}SMART  = \u5371\u9669\u64cd\u4f5c\u624d\u9700\u786e\u8ba4{C.R}')
            print(f'  {C.GR}AUTO   = \u81ea\u52a8\u6267\u884c (\u63a8\u8350){C.R}')
            print(f'  {C.GR}OFF    = \u5b8c\u5168\u81ea\u52a8\uff0c\u65e0\u786e\u8ba4{C.R}')
            new = prompt('\u5ba1\u6279\u7ea7\u522b', approval)
            if new.upper() in ('STRICT', 'SMART', 'AUTO', 'OFF'):
                set_nested(config, ['agents', 'running', 'approval_level'], new.upper())
                save_json(CONFIG_JSON, config)
                print(f'\n  {C.GRN}\u2705 \u5ba1\u6279\u7ea7\u522b\u5df2\u8bbe\u4e3a: {new.upper()}{C.R}')
            else:
                print(f'\n  {C.RED}\u65e0\u6548\u9009\u9879{C.R}')
            pause()
        elif idx == 2:
            new = prompt('\u6700\u5927\u63a8\u7406\u8fed\u4ee3\u6b21\u6570', str(max_iters))
            try:
                set_nested(config, ['agents', 'running', 'max_iters'], int(new))
                save_json(CONFIG_JSON, config)
                print(f'\n  {C.GRN}\u2705 \u5df2\u8bbe\u4e3a: {new}{C.R}')
            except ValueError:
                print(f'\n  {C.RED}\u8bf7\u8f93\u5165\u6570\u5b57{C.R}')
            pause()
        elif idx == 3:
            new = prompt('\u4e0a\u4e0b\u6587\u957f\u5ea6 (tokens)', str(max_input))
            try:
                set_nested(config, ['agents', 'running', 'max_input_length'], int(new))
                save_json(CONFIG_JSON, config)
                print(f'\n  {C.GRN}\u2705 \u5df2\u8bbe\u4e3a: {new}{C.R}')
            except ValueError:
                print(f'\n  {C.RED}\u8bf7\u8f93\u5165\u6570\u5b57{C.R}')
            pause()
        elif idx == 4:
            new = prompt('Shell \u547d\u4ee4\u8d85\u65f6 (\u79d2)', str(cmd_timeout))
            try:
                set_nested(config, ['agents', 'running', 'shell_command_timeout'], float(new))
                save_json(CONFIG_JSON, config)
                print(f'\n  {C.GRN}\u2705 \u5df2\u8bbe\u4e3a: {new}s{C.R}')
            except ValueError:
                print(f'\n  {C.RED}\u8bf7\u8f93\u5165\u6570\u5b57{C.R}')
            pause()

# --- Section 3: Mode Switch ---

def section_mode():
    """Switch between online and offline mode."""
    env_path = USB_ROOT / 'config' / 'portable.env'
    config = load_json(CONFIG_JSON)

    current = 'online'
    if env_path.exists():
        content = env_path.read_text(encoding='utf-8')
        if 'QP_MODEL_MODE=local' in content:
            current = 'local'

    active = get_active_model()
    provider_id = active.get('provider_id', '')
    model = active.get('model', '')

    print(f'\n  {C.B}\u2550\u2550\u2550 \u8fd0\u884c\u6a21\u5f0f\u5207\u6362 \u2550\u2550\u2550{C.R}')
    print(f'  \u5f53\u524d\u6a21\u5f0f: {C.GRN}{"\u79bb\u7ebf" if current == "local" else "\u5728\u7ebf"}{C.R}')
    print(f'  \u5f53\u524d\u63d0\u4f9b\u5546: {provider_id or "\u672a\u914d\u7f6e"} / {model or "\u672a\u914d\u7f6e"}')
    print()
    print(f'    {C.B}[1]{C.R} \u5728\u7ebf\u6a21\u5f0f \u2014 \u8c03\u7528\u4e91\u7aef API\uff0c\u9700\u8981\u7f51\u7edc')
    print(f'    {C.B}[2]{C.R} \u79bb\u7ebf\u6a21\u5f0f \u2014 \u672c\u5730\u6a21\u578b\u63a8\u7406\uff0c\u5b8c\u5168\u79bb\u7ebf')
    print(f'    {C.B}[3]{C.R} \u53cc\u6a21\u5f0f\u8def\u7531 \u2014 \u7b80\u5355\u4efb\u52a1\u8d70\u672c\u5730\uff0c\u590d\u6742\u4efb\u52a1\u8d70\u4e91\u7aef')
    print(f'    {C.D}[0] \u8fd4\u56de{C.R}')
    print()

    raw = input('  \u8bf7\u9009\u62e9 > ').strip()

    if raw == '1':
        if env_path.exists():
            content = env_path.read_text(encoding='utf-8')
            content = content.replace('QP_MODEL_MODE=local', 'QP_MODEL_MODE=online')
            env_path.write_text(content, encoding='utf-8')
        set_nested(config, ['agents', 'llm_routing', 'enabled'], False)
        save_json(CONFIG_JSON, config)
        print(f'\n  {C.GRN}\u2705 \u5df2\u5207\u6362\u5230\u5728\u7ebf\u6a21\u5f0f{C.R}')

    elif raw == '2':
        if env_path.exists():
            content = env_path.read_text(encoding='utf-8')
            content = content.replace('QP_MODEL_MODE=online', 'QP_MODEL_MODE=local')
            env_path.write_text(content, encoding='utf-8')
        else:
            env_path.parent.mkdir(parents=True, exist_ok=True)
            env_path.write_text('QP_MODEL_MODE=local\n', encoding='utf-8')
        set_nested(config, ['agents', 'llm_routing', 'enabled'], False)
        save_json(CONFIG_JSON, config)
        print(f'\n  {C.ORG}\u2705 \u5df2\u5207\u6362\u5230\u79bb\u7ebf\u6a21\u5f0f{C.R}')

    elif raw == '3':
        cloud_pid = provider_id or 'dashscope'
        cloud_model = model or 'qwen-plus'

        local_pid = prompt('\u672c\u5730\u63d0\u4f9b\u5546 ID', 'ollama')
        local_model = prompt('\u672c\u5730\u6a21\u578b\u540d\u79f0', 'qwen2.5:7b')

        set_nested(config, ['agents', 'llm_routing', 'enabled'], True)
        set_nested(config, ['agents', 'llm_routing', 'mode'], 'local_first')
        set_nested(config, ['agents', 'llm_routing', 'local', 'provider_id'], local_pid)
        set_nested(config, ['agents', 'llm_routing', 'local', 'model'], local_model)
        set_nested(config, ['agents', 'llm_routing', 'cloud', 'provider_id'], cloud_pid)
        set_nested(config, ['agents', 'llm_routing', 'cloud', 'model'], cloud_model)
        save_json(CONFIG_JSON, config)

        if env_path.exists():
            content = env_path.read_text(encoding='utf-8')
            content = content.replace('QP_MODEL_MODE=local', 'QP_MODEL_MODE=online')
            env_path.write_text(content, encoding='utf-8')

        print(f'\n  {C.CYN}\u2705 \u5df2\u542f\u7528\u53cc\u6a21\u5f0f\u8def\u7531 (\u672c\u5730\u4f18\u5148){C.R}')
        print(f'  \u672c\u5730: {local_pid}/{local_model}')
        print(f'  \u4e91\u7aef: {cloud_pid}/{cloud_model}')

    pause()

# --- Section 4: Security ---

def section_security():
    """Configure security settings."""
    config = load_json(CONFIG_JSON)
    if not config:
        print(f'\n  {C.RED}[\u21a9] config.json \u4e0d\u5b58\u5728{C.R}')
        pause()
        return

    while True:
        clear()
        show_banner()

        tg = get_nested(config, ['security', 'tool_guard'], {})
        fg = get_nested(config, ['security', 'file_guard'], {})
        ss = get_nested(config, ['security', 'skill_scanner'], {})

        tg_enabled = tg.get('enabled', True) if isinstance(tg, dict) else True
        fg_enabled = fg.get('enabled', True) if isinstance(fg, dict) else True
        ss_enabled = ss.get('enabled', True) if isinstance(ss, dict) else True

        print(f'\n  {C.B}\u2550\u2550\u2550 \u5b89\u5168\u914d\u7f6e \u2550\u2550\u2550{C.R}')
        items = [
            f'\u5de5\u5177\u5b88\u536b (Tool Guard)     {C.GRN}{"\u5df2\u542f\u7528" if tg_enabled else C.RED + "\u5df2\u7981\u7528" + C.R}{C.GR} \u2014 \u62e6\u622a\u5371\u9669\u547d\u4ee4{C.R}',
            f'\u6587\u4ef6\u9632\u62a4 (File Guard)     {C.GRN}{"\u5df2\u542f\u7528" if fg_enabled else C.RED + "\u5df2\u7981\u7528" + C.R}{C.GR} \u2014 \u9650\u5236\u6587\u4ef6\u8bbf\u95ee\u8303\u56f4{C.R}',
            f'\u6280\u80fd\u626b\u63cf (Skill Scanner)  {C.GRN}{"\u5df2\u542f\u7528" if ss_enabled else C.RED + "\u5df2\u7981\u7528" + C.R}{C.GR} \u2014 \u5b89\u88c5\u524d\u5b89\u5168\u68c0\u67e5{C.R}',
        ]
        idx = choice_menu(items, '\u5b89\u5168\u8bbe\u7f6e')
        if idx == -1:
            break

        if idx == 0:
            new_val = not tg_enabled
            set_nested(config, ['security', 'tool_guard', 'enabled'], new_val)
            save_json(CONFIG_JSON, config)
            print(f'\n  {C.GRN}\u2705 \u5de5\u5177\u5b88\u536b: {"\u5df2\u542f\u7528" if new_val else "\u5df2\u7981\u7528"}{C.R}')
            pause()
        elif idx == 1:
            new_val = not fg_enabled
            set_nested(config, ['security', 'file_guard', 'enabled'], new_val)
            save_json(CONFIG_JSON, config)
            print(f'\n  {C.GRN}\u2705 \u6587\u4ef6\u9632\u62a4: {"\u5df2\u542f\u7528" if new_val else "\u5df2\u7981\u7528"}{C.R}')
            pause()
        elif idx == 2:
            new_val = not ss_enabled
            set_nested(config, ['security', 'skill_scanner', 'enabled'], new_val)
            save_json(CONFIG_JSON, config)
            print(f'\n  {C.GRN}\u2705 \u6280\u80fd\u626b\u63cf: {"\u5df2\u542f\u7528" if new_val else "\u5df2\u7981\u7528"}{C.R}')
            pause()

# --- Section 5: View Config ---

def section_view():
    """View all current configuration."""
    clear()
    show_banner()

    print(f'\n  {C.B}\u2550\u2550\u2550 \u914d\u7f6e\u603b\u89c8 \u2550\u2550\u2550{C.R}')

    # Active model
    active = get_active_model()
    print(f'\n  {C.ORG}\u25b8 \u6d3b\u8dc3\u6a21\u578b{C.R}')
    print(f'    \u63d0\u4f9b\u5546: {active.get("provider_id", "\u672a\u914d\u7f6e")}')
    print(f'    \u6a21\u578b:   {active.get("model", "\u672a\u914d\u7f6e")}')

    # Provider details
    pid = active.get('provider_id', '')
    pconfig = get_provider_config(pid)
    if pconfig:
        key = pconfig.get('api_key', '')
        masked = key[:6] + '****' + key[-4:] if len(key) > 12 else ('\u5df2\u914d\u7f6e' if key else '\u672a\u914d\u7f6e')
        print(f'    API\u5730\u5740: {pconfig.get("base_url", "")}')
        print(f'    API Key: {masked}')

    # config.json
    config = load_json(CONFIG_JSON)
    if config:
        print(f'\n  {C.ORG}\u25b8 Agent \u8bbe\u7f6e{C.R}')
        print(f'    \u8bed\u8a00:     {get_nested(config, ["agents", "language"], "zh")}')
        print(f'    \u5ba1\u6279\u7ea7\u522b: {get_nested(config, ["agents", "running", "approval_level"], "AUTO")}')
        print(f'    \u6700\u5927\u8fed\u4ee3: {get_nested(config, ["agents", "running", "max_iters"], 100)}')
        print(f'    \u4e0a\u4e0b\u6587:   {get_nested(config, ["agents", "running", "max_input_length"], 131072)}')

        routing = get_nested(config, ['agents', 'llm_routing', 'enabled'], False)
        if routing:
            mode = get_nested(config, ['agents', 'llm_routing', 'mode'], '')
            local_p = get_nested(config, ['agents', 'llm_routing', 'local', 'provider_id'], '')
            local_m = get_nested(config, ['agents', 'llm_routing', 'local', 'model'], '')
            cloud_p = get_nested(config, ['agents', 'llm_routing', 'cloud', 'provider_id'], '')
            cloud_m = get_nested(config, ['agents', 'llm_routing', 'cloud', 'model'], '')
            print(f'    \u8def\u7531\u6a21\u5f0f: {mode} (\u672c\u5730: {local_p}/{local_m}, \u4e91\u7aef: {cloud_p}/{cloud_m})')
        else:
            print(f'    \u8def\u7531\u6a21\u5f0f: \u672a\u542f\u7528 (\u5355\u6a21\u578b)')

        print(f'\n  {C.ORG}\u25b8 \u5b89\u5168\u8bbe\u7f6e{C.R}')
        tg = get_nested(config, ['security', 'tool_guard', 'enabled'], True)
        fg = get_nested(config, ['security', 'file_guard', 'enabled'], True)
        ss = get_nested(config, ['security', 'skill_scanner', 'enabled'], True)
        print(f'    \u5de5\u5177\u5b88\u536b: {"\u2705" if tg else "\u274c"}')
        print(f'    \u6587\u4ef6\u9632\u62a4: {"\u2705" if fg else "\u274c"}')
        print(f'    \u6280\u80fd\u626b\u63cf: {"\u2705" if ss else "\u274c"}')

        print(f'\n  {C.ORG}\u25b8 \u6e20\u9053\u914d\u7f6e{C.R}')
        channels = get_nested(config, ['channels'], {})
        for ch_name, ch_conf in channels.items():
            if isinstance(ch_conf, dict):
                enabled = ch_conf.get('enabled', False)
                print(f'    {ch_name}: {"\u2705 \u5df2\u542f\u7528" if enabled else "\u2b1c \u672a\u542f\u7528"}')

    # Mode
    env_path = USB_ROOT / 'config' / 'portable.env'
    mode = '\u5728\u7ebf'
    if env_path.exists() and 'QP_MODEL_MODE=local' in env_path.read_text(encoding='utf-8'):
        mode = '\u79bb\u7ebf'
    print(f'\n  {C.ORG}\u25b8 \u8fd0\u884c\u6a21\u5f0f{C.R}')
    print(f'    {mode}')

    print()
    pause()

# --- Section 6: Raw JSON Editor ---

def section_raw_json():
    """Direct JSON editing for advanced users."""
    print(f'\n  {C.B}\u2550\u2550\u2550 \u9ad8\u7ea7: \u76f4\u63a5\u7f16\u8f91 JSON \u2550\u2550\u2550{C.R}')
    print(f'  {C.YEL}\u26a0\ufe0f  \u8bf7\u8c28\u614e\u64cd\u4f5c\uff0c\u683c\u5f0f\u9519\u8bef\u53ef\u80fd\u5bfc\u81f4\u914d\u7f6e\u5931\u6548{C.R}\n')

    items = [
        f'\u7f16\u8f91 config.json         {C.GR}\u4e3b\u914d\u7f6e\u6587\u4ef6{C.R}',
        f'\u7f16\u8f91 active_model.json   {C.GR}\u6d3b\u8dc3\u6a21\u578b\u9009\u62e9{C.R}',
        f'\u7f16\u8f91\u63d0\u4f9b\u5546\u914d\u7f6e           {C.GR}builtin/custom provider JSON{C.R}',
    ]
    idx = choice_menu(items, 'JSON \u6587\u4ef6\u7f16\u8f91')
    if idx == -1:
        return

    if idx == 0:
        path = CONFIG_JSON
    elif idx == 1:
        path = ACTIVE_MODEL_JSON
    elif idx == 2:
        files = []
        if PROVIDERS_DIR.exists():
            files.extend(PROVIDERS_DIR.glob('*.json'))
        if CUSTOM_PROVIDERS_DIR.exists():
            files.extend(CUSTOM_PROVIDERS_DIR.glob('*.json'))
        if not files:
            print(f'\n  {C.RED}\u672a\u627e\u5230\u63d0\u4f9b\u5546\u914d\u7f6e\u6587\u4ef6{C.R}')
            pause()
            return
        items = [f.name for f in files]
        pidx = choice_menu(items, '\u9009\u62e9\u6587\u4ef6')
        if pidx < 0:
            return
        path = files[pidx]
    else:
        return

    if not path.exists():
        print(f'\n  {C.RED}\u6587\u4ef6\u4e0d\u5b58\u5728: {path}{C.R}')
        pause()
        return

    data = load_json(path)
    print(f'\n  {C.B}\u6587\u4ef6: {path}{C.R}')
    print(f'  {C.D}{"─" * 50}{C.R}')
    formatted = json.dumps(data, indent=2, ensure_ascii=False)
    for line in formatted.split('\n'):
        print(f'  {line}')
    print(f'  {C.D}{"─" * 50}{C.R}')
    print(f'\n  {C.GR}\u63d0\u793a: \u590d\u5236\u4e0a\u65b9 JSON\uff0c\u4fee\u6539\u540e\u7c98\u8d34\u5230\u4e0b\u65b9 (\u8f93\u5165\u7a7a\u884c\u7ed3\u675f){C.R}')
    print(f'  {C.GR}\u76f4\u63a5\u56de\u8f66\u8df3\u8fc7\u4e0d\u4fee\u6539{C.R}\n')

    lines = []
    while True:
        line = input()
        if line == '' and not lines:
            print(f'  {C.GR}\u672a\u4fee\u6539{C.R}')
            pause()
            return
        if line == '':
            break
        lines.append(line)

    raw = '\n'.join(lines)
    try:
        new_data = json.loads(raw)
        save_json(path, new_data)
        print(f'\n  {C.GRN}\u2705 \u5df2\u4fdd\u5b58{C.R}')
    except json.JSONDecodeError as e:
        print(f'\n  {C.RED}\u274c JSON \u683c\u5f0f\u9519\u8bef: {e}{C.R}')
        print(f'  {C.GR}\u539f\u6587\u4ef6\u672a\u4fee\u6539{C.R}')

    pause()

# --- Main entry ---

def main():
    enable_vtp()

    # Check if workspace is initialized
    if not CONFIG_JSON.exists():
        clear()
        show_banner()
        print(f'\n  {C.RED}[\u21a9] \u5de5\u4f5c\u533a\u672a\u521d\u59cb\u5316\uff01{C.R}')
        print(f'  \u8bf7\u5148\u8fd0\u884c setup \u5b89\u88c5\u73af\u5883\uff0c\u6216\u6267\u884c:')
        print(f'    set QWENPAW_WORKING_DIR={WORKING_DIR}')
        print(f'    python -m qwenpaw init --defaults')
        pause()
        sys.exit(1)

    while True:
        clear()
        show_banner()
        show_current_status()

        items = [
            f'\u6a21\u578b\u4e0e\u63d0\u4f9b\u5546  {C.GR}\u5207\u6362\u63d0\u4f9b\u5546/\u6a21\u578b\u3001\u8bbe\u7f6e API Key{C.R}',
            f'\u8fd0\u884c\u6a21\u5f0f      {C.GR}\u5728\u7ebf/\u79bb\u7ebf/\u53cc\u6a21\u5f0f\u8def\u7531{C.R}',
            f'Agent \u8bbe\u7f6e    {C.GR}\u8bed\u8a00\u3001\u5ba1\u6279\u7ea7\u522b\u3001\u63a8\u7406\u53c2\u6570{C.R}',
            f'\u5b89\u5168\u914d\u7f6e      {C.GR}\u5de5\u5177\u5b88\u536b/\u6587\u4ef6\u9632\u62a4/\u6280\u80fd\u626b\u63cf{C.R}',
            f'\u67e5\u770b\u5b8c\u6574\u914d\u7f6e  {C.GR}\u663e\u793a\u6240\u6709\u914d\u7f6e\u8be6\u60c5{C.R}',
            f'\u9ad8\u7ea7\u7f16\u8f91      {C.GR}\u76f4\u63a5\u4fee\u6539 JSON \u6587\u4ef6{C.R}',
        ]

        print()
        for i, item in enumerate(items, 1):
            print(f'  {C.B}[{i}]{C.R} {item}')
        print(f'  {C.D}[0] \u9000\u51fa{C.R}')
        print()

        choice = input('  \u8bf7\u9009\u62e9 > ').strip()

        if choice in ('0', 'q', 'Q'):
            clear()
            print(f'\n  \u518d\u89c1! \ud83d\udc3e\n')
            sys.exit(0)
        elif choice == '1':
            section_model_provider()
        elif choice == '2':
            section_mode()
        elif choice == '3':
            section_agent()
        elif choice == '4':
            section_security()
        elif choice == '5':
            section_view()
        elif choice == '6':
            section_raw_json()

if __name__ == '__main__':
    main()
