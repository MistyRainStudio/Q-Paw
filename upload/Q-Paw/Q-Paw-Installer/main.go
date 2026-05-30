package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

const version = "2.0"

func main() {
	// Find USB root (directory where this EXE lives)
	exePath, _ := os.Executable()
	usbRoot := filepath.Dir(exePath)

	// Also check if we're inside Windows/ subfolder
	parentDir := filepath.Dir(usbRoot)
	if filepath.Base(usbRoot) == "Windows" {
		usbRoot = parentDir
	}

	for {
		clearScreen()
		showBanner()
		showStatus(usbRoot)
		showMenu()

		choice := readInput("\n  请选择 > ")
		switch strings.TrimSpace(choice) {
		case "1":
			runSetup(usbRoot)
		case "2":
			runLaunch(usbRoot)
		case "3":
			runModelManager(usbRoot)
		case "4":
			runUpdate(usbRoot)
		case "5":
			runMigrate(usbRoot)
		case "6":
			editConfig(usbRoot)
		case "7":
			runCleanup(usbRoot)
		case "0", "q", "Q":
			fmt.Println("\n  再见! 🐾")
			return
		default:
			fmt.Println("\n  [!] 无效选择，按回车继续...")
			readInput("")
		}
	}
}

func showBanner() {
	fmt.Println("  ╔═══════════════════════════════════════════╗")
	fmt.Println("  ║            Q-Paw 便携助手 v" + version + "           ║")
	fmt.Println("  ║        QwenPaw U盘启动器 - 即插即用       ║")
	fmt.Println("  ╚═══════════════════════════════════════════╝")
}

func showStatus(usbRoot string) {
	fmt.Println()

	// Check Python
	pyPath := filepath.Join(usbRoot, "python", "python.exe")
	pyStatus := "❌ 未安装"
	if fileExists(pyPath) {
		pyStatus = "✅ 已安装"
	}

	// Check uv
	uvPath := filepath.Join(usbRoot, "bin", "uv.exe")
	uvStatus := "❌ 未安装"
	if fileExists(uvPath) {
		uvStatus = "✅ 已安装"
	}

	// Check QwenPaw
	qpStatus := "❌ 未安装"
	if pyExists(usbRoot) {
		cmd := exec.Command(pyPath, "-c", "import qwenpaw")
		if cmd.Run() == nil {
			qpStatus = "✅ 已安装"
		}
	}

	// Count models
	modelCount := 0
	modelsDir := filepath.Join(usbRoot, "models")
	if entries, err := os.ReadDir(modelsDir); err == nil {
		for _, e := range entries {
			if e.IsDir() {
				modelCount++
			}
		}
	}

	// Read mode from config
	mode := "在线"
	envPath := filepath.Join(usbRoot, "config", "portable.env")
	if data, err := os.ReadFile(envPath); err == nil {
		if strings.Contains(string(data), "QP_MODEL_MODE=local") {
			mode = "离线"
		}
	}

	fmt.Println("  ┌─ 系统状态 ────────────────────────────────┐")
	fmt.Printf("  │  Python:  %-12s  uv: %-12s │\n", pyStatus, uvStatus)
	fmt.Printf("  │  QwenPaw: %-12s  模型: %-10d │\n", qpStatus, modelCount)
	fmt.Printf("  │  运行模式: %-30s │\n", mode)
	fmt.Println("  └──────────────────────────────────────────┘")
}

func showMenu() {
	fmt.Println()
	fmt.Println("  [1] 📥 安装环境      首次使用必选 (安装 uv + Python + QwenPaw)")
	fmt.Println("  [2] 🚀 启动 QwenPaw  在线/离线模式启动")
	fmt.Println("  [3] 📦 模型管理      下载/导入/删除本地模型")
	fmt.Println("  [4] 🔄 更新          更新 QwenPaw + modelscope + uv")
	fmt.Println("  [5] 🔀 数据迁移      从旧版 Q-Paw 合并数据")
	fmt.Println("  [6] ⚙️  配置          编辑 API Key / 运行模式等")
	fmt.Println("  [7] 🧹 清理          清理缓存和临时文件")
	fmt.Println()
	fmt.Println("  [0] 退出")
}

func runSetup(usbRoot string) {
	fmt.Println("\n  ═══ 📥 安装环境 ═══")
	fmt.Println()
	script := filepath.Join(usbRoot, "Windows", "setup.bat")
	if !fileExists(script) {
		script = filepath.Join(usbRoot, "setup.bat")
	}
	runBatch(script)
}

func runLaunch(usbRoot string) {
	fmt.Println("\n  ═══ 🚀 启动 QwenPaw ═══")
	fmt.Println()
	script := filepath.Join(usbRoot, "Windows", "launch.bat")
	if !fileExists(script) {
		script = filepath.Join(usbRoot, "launch.bat")
	}
	runBatch(script)
}

func runModelManager(usbRoot string) {
	fmt.Println("\n  ═══ 📦 模型管理 ═══")
	fmt.Println()
	script := filepath.Join(usbRoot, "Windows", "model-manager.bat")
	if !fileExists(script) {
		script = filepath.Join(usbRoot, "model-manager.bat")
	}
	runBatch(script)
}

func runUpdate(usbRoot string) {
	fmt.Println("\n  ═══ 🔄 更新 ═══")
	fmt.Println()
	script := filepath.Join(usbRoot, "Windows", "update.bat")
	if !fileExists(script) {
		script = filepath.Join(usbRoot, "update.bat")
	}
	runBatch(script)
}

func runMigrate(usbRoot string) {
	fmt.Println("\n  ═══ 🔀 数据迁移 ═══")
	fmt.Println()
	script := filepath.Join(usbRoot, "Windows", "migrate.bat")
	if !fileExists(script) {
		script = filepath.Join(usbRoot, "migrate.bat")
	}
	runBatch(script)
}

func editConfig(usbRoot string) {
	fmt.Println("\n  ═══ ⚙️  配置 ═══")
	fmt.Println()

	envPath := filepath.Join(usbRoot, "config", "portable.env")
	if !fileExists(envPath) {
		fmt.Println("  配置文件不存在，将创建默认配置...")
		os.MkdirAll(filepath.Join(usbRoot, "config"), 0755)
		content := `# Q-Paw 便携模式配置
QP_PORTABLE_MODE=1
QP_MODEL_MODE=online
QP_TOOL_GUARD=1
QP_FILE_GUARD=1
QP_SKILL_SCAN=1
`
		os.WriteFile(envPath, []byte(content), 0644)
	}

	for {
		fmt.Println("  配置项:")
		fmt.Println("    [1] 切换运行模式 (在线/离线)")
		fmt.Println("    [2] 配置 API Key")
		fmt.Println("    [3] 查看当前配置")
		fmt.Println("    [0] 返回")
		fmt.Println()

		choice := readInput("  请选择 > ")
		switch strings.TrimSpace(choice) {
		case "1":
			switchMode(envPath)
		case "2":
			configAPI(usbRoot, envPath)
		case "3":
			showConfig(envPath)
		case "0":
			return
		}
	}
}

func switchMode(envPath string) {
	data, err := os.ReadFile(envPath)
	if err != nil {
		fmt.Println("  [!] 无法读取配置文件")
		return
	}
	content := string(data)

	if strings.Contains(content, "QP_MODEL_MODE=online") {
		content = strings.Replace(content, "QP_MODEL_MODE=online", "QP_MODEL_MODE=local", 1)
		fmt.Println("  ✅ 已切换到离线模式")
	} else {
		content = strings.Replace(content, "QP_MODEL_MODE=local", "QP_MODEL_MODE=online", 1)
		fmt.Println("  ✅ 已切换到在线模式")
	}
	os.WriteFile(envPath, []byte(content), 0644)
	readInput("  按回车继续...")
}

func configAPI(usbRoot string, envPath string) {
	fmt.Println("\n  选择 API 提供商:")
	fmt.Println("    [1] DashScope (阿里云百炼) — 推荐，国内直连")
	fmt.Println("    [2] OpenAI")
	fmt.Println("    [3] OpenRouter")
	fmt.Println("    [4] ModelScope (魔搭)")
	fmt.Println("    [0] 返回")
	fmt.Println()

	choice := readInput("  请选择 > ")
	var provider string
	switch strings.TrimSpace(choice) {
	case "1":
		provider = "dashscope"
	case "2":
		provider = "openai"
	case "3":
		provider = "openrouter"
	case "4":
		provider = "modelscope"
	default:
		return
	}

	fmt.Println()
	apiKey := readInput("  请输入 API Key: ")
	if strings.TrimSpace(apiKey) == "" {
		fmt.Println("  [!] API Key 不能为空")
		return
	}

	// Read existing config
	data, err := os.ReadFile(envPath)
	content := ""
	if err == nil {
		content = string(data)
	} else {
		content = "# Q-Paw 便携模式配置\nQP_PORTABLE_MODE=1\nQP_MODEL_MODE=online\n"
	}

	// Update or add provider and key
	content = updateOrAddLine(content, "QP_API_PROVIDER", provider)
	content = updateOrAddLine(content, "QP_API_KEY", strings.TrimSpace(apiKey))

	os.WriteFile(envPath, []byte(content), 0644)
	fmt.Println("  ✅ API 配置已保存!")
	readInput("  按回车继续...")
}

func showConfig(envPath string) {
	data, err := os.ReadFile(envPath)
	if err != nil {
		fmt.Println("  [!] 无法读取配置文件")
		return
	}
	fmt.Println()
	fmt.Println("  ┌─ 当前配置 ────────────────────────────────┐")
	for _, line := range strings.Split(string(data), "\n") {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}
		if strings.HasPrefix(trimmed, "#") {
			// Mask API keys for security
			continue
		}
		// Mask API key values
		if strings.HasPrefix(trimmed, "QP_API_KEY=") {
			parts := strings.SplitN(trimmed, "=", 2)
			if len(parts) == 2 && len(parts[1]) > 8 {
				masked := parts[1][:4] + "****" + parts[1][len(parts[1])-4:]
				fmt.Printf("  │  %s=%s\n", parts[0], masked)
				continue
			}
		}
		fmt.Printf("  │  %s\n", trimmed)
	}
	fmt.Println("  └──────────────────────────────────────────┘")
	readInput("\n  按回车继续...")
}

func runCleanup(usbRoot string) {
	fmt.Println("\n  ═══ 🧹 清理 ═══")
	fmt.Println()
	script := filepath.Join(usbRoot, "Windows", "cleanup.bat")
	if !fileExists(script) {
		script = filepath.Join(usbRoot, "cleanup.bat")
	}
	runBatch(script)
}

// ─── Helper Functions ───

func runBatch(script string) {
	if !fileExists(script) {
		fmt.Printf("  [!] 脚本未找到: %s\n", script)
		readInput("  按回车继续...")
		return
	}

	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("cmd", "/C", script)
	} else {
		// On non-Windows, just show what would run (for testing)
		fmt.Printf("  [i] 将执行: %s\n", script)
		readInput("  按回车继续...")
		return
	}

	cmd.Dir = filepath.Dir(script)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	fmt.Printf("  [i] 执行: %s\n\n", script)
	cmd.Run()
	fmt.Println()
	readInput("  按回车继续...")
}

func updateOrAddLine(content, key, value string) string {
	lines := strings.Split(content, "\n")
	found := false
	for i, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), key+"=") {
			lines[i] = key + "=" + value
			found = true
			break
		}
	}
	if !found {
		lines = append(lines, key+"="+value)
	}
	return strings.Join(lines, "\n")
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func pyExists(usbRoot string) bool {
	pyPath := filepath.Join(usbRoot, "python", "python.exe")
	return fileExists(pyPath)
}

func clearScreen() {
	if runtime.GOOS == "windows" {
		cmd := exec.Command("cmd", "/C", "cls")
		cmd.Stdout = os.Stdout
		cmd.Run()
	} else {
		fmt.Print("\033[H\033[2J")
	}
}

func readInput(prompt string) string {
	fmt.Print(prompt)
	var input string
	fmt.Scanln(&input)
	return input
}
