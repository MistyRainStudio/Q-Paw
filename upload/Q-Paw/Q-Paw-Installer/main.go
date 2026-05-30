package main

import (
        "fmt"
        "os"
        "os/exec"
        "path/filepath"
        "runtime"
        "strings"
        "syscall"
        "unsafe"
)

const version = "2.0"

var (
        kernel32           = syscall.NewLazyDLL("kernel32.dll")
        procGetStdHandle   = kernel32.NewProc("GetStdHandle")
        procSetConsoleMode = kernel32.NewProc("SetConsoleMode")
        // Virtual Terminal colors
        colorReset  = "\033[0m"
        colorBold   = "\033[1m"
        colorOrange = "\033[38;5;208m" // Q-Paw brand orange
        colorGreen  = "\033[32m"
        colorRed    = "\033[31m"
        colorGray   = "\033[90m"
        colorDim    = "\033[37m"
        bgOrange    = "\033[48;5;208m\033[30m" // orange bg + black text
)

func main() {
        // Enable Virtual Terminal Processing for ANSI colors on Windows
        enableVTP()

        // Set console to white background, black text via Windows API
        setConsoleColor()

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
                        clearScreen()
                        fmt.Println("\n  再见! 🐾\n")
                        return
                default:
                        fmt.Println("\n  [!] 无效选择，按回车继续...")
                        readInput("")
                }
        }
}

// enableVTP enables Virtual Terminal Processing for ANSI escape sequences
func enableVTP() {
        if runtime.GOOS != "windows" {
                return
        }
        stdoutHandle, _, _ := procGetStdHandle.Call(uintptr(0xFFFFFFF5)) // STD_OUTPUT_HANDLE
        procSetConsoleMode.Call(stdoutHandle, 0)
        procSetConsoleMode.Call(stdoutHandle, uintptr(0x0007)) // ENABLE_VIRTUAL_TERMINAL_PROCESSING
}

// setConsoleColor fills the console with white background
func setConsoleColor() {
        if runtime.GOOS != "windows" {
                return
        }
        // Use Windows API to set default console attributes: white bg (0xF0) + black text (0x0)
        stdoutHandle, _, _ := procGetStdHandle.Call(uintptr(0xFFFFFFF5))

        // SetConsoleTextAttribute: white background (0xF0) + black text (0x0) = 0xF0
        setTextAttr := kernel32.NewProc("SetConsoleTextAttribute")
        setTextAttr.Call(stdoutHandle, uintptr(0xF0)) // 0xF0 = white bg, black text

        // Fill the entire console buffer with white background
        fillConsole(stdoutHandle)
}

func fillConsole(stdoutHandle uintptr) {
        // Get console screen buffer info
        getCSBI := kernel32.NewProc("GetConsoleScreenBufferInfo")
        var csbi consoleScreenBufferInfo
        getCSBI.Call(stdoutHandle, uintptr(unsafe.Pointer(&csbi)))

        // Fill entire buffer with spaces on white background
        fillCOW := kernel32.NewProc("FillConsoleOutputCharacterW")
        fillCOA := kernel32.NewProc("FillConsoleOutputAttribute")

        totalCells := int(csbi.Size.X) * int(csbi.Size.Y)
        coord := uint32(0)

        var written uint32
        fillCOW.Call(stdoutHandle, uintptr(' '), uintptr(totalCells), uintptr(unsafe.Pointer(&coord)), uintptr(unsafe.Pointer(&written)))
        fillCOA.Call(stdoutHandle, uintptr(0xF0), uintptr(totalCells), uintptr(unsafe.Pointer(&coord)), uintptr(unsafe.Pointer(&written)))

        // Move cursor to top-left
        setCCP := kernel32.NewProc("SetConsoleCursorPosition")
        setCCP.Call(stdoutHandle, uintptr(unsafe.Pointer(&coord)))
}

type consoleScreenBufferInfo struct {
        Size              coord
        CursorPosition    coord
        Attributes        uint16
        Window            smallRect
        MaximumWindowSize coord
}

type coord struct {
        X int16
        Y int16
}

type smallRect struct {
        Left   int16
        Top    int16
        Right  int16
        Bottom int16
}

func showBanner() {
        fmt.Println()
        fmt.Println("  " + colorBold + colorOrange + "╔═══════════════════════════════════════════╗" + colorReset)
        fmt.Println("  " + colorBold + colorOrange + "║" + colorReset + "            " + colorBold + "Q-Paw 便携助手 v" + version + "           " + colorOrange + "║" + colorReset)
        fmt.Println("  " + colorBold + colorOrange + "║" + colorReset + "        " + colorBold + "QwenPaw U盘启动器 - 即插即用       " + colorOrange + "║" + colorReset)
        fmt.Println("  " + colorBold + colorOrange + "╚═══════════════════════════════════════════╝" + colorReset)
}

func showStatus(usbRoot string) {
        fmt.Println()

        // Check Python
        pyPath := filepath.Join(usbRoot, "python", "python.exe")
        pyStatus := colorRed + "未安装" + colorReset
        if fileExists(pyPath) {
                pyStatus = colorGreen + "已安装" + colorReset
        }

        // Check uv
        uvPath := filepath.Join(usbRoot, "bin", "uv.exe")
        uvStatus := colorRed + "未安装" + colorReset
        if fileExists(uvPath) {
                uvStatus = colorGreen + "已安装" + colorReset
        }

        // Check QwenPaw
        qpStatus := colorRed + "未安装" + colorReset
        if pyExists(usbRoot) {
                cmd := exec.Command(pyPath, "-c", "import qwenpaw")
                if cmd.Run() == nil {
                        qpStatus = colorGreen + "已安装" + colorReset
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
        modeColor := colorGreen
        envPath := filepath.Join(usbRoot, "config", "portable.env")
        if data, err := os.ReadFile(envPath); err == nil {
                if strings.Contains(string(data), "QP_MODEL_MODE=local") {
                        mode = "离线"
                        modeColor = colorOrange
                }
        }

        // Check workspace init (config.json in data/)
        initStatus := colorRed + "未初始化" + colorReset
        configJsonPath := filepath.Join(usbRoot, "data", "config.json")
        if fileExists(configJsonPath) {
                initStatus = colorGreen + "已初始化" + colorReset
        }

        fmt.Println("  " + colorDim + "┌─ 系统状态 ────────────────────────────────┐" + colorReset)
        fmt.Printf("  "+colorDim+"│"+colorReset+"  Python:  %-20s uv: %-14s"+colorDim+"│"+colorReset+"\n", pyStatus, uvStatus)
        fmt.Printf("  "+colorDim+"│"+colorReset+"  QwenPaw: %-20s 模型: %-4d"+colorDim+"         │"+colorReset+"\n", qpStatus, modelCount)
        fmt.Printf("  "+colorDim+"│"+colorReset+"  工作区:  %-30s"+colorDim+"│"+colorReset+"\n", initStatus)
        fmt.Printf("  "+colorDim+"│"+colorReset+"  运行模式: %-30s"+colorDim+"│"+colorReset+"\n", modeColor+mode+colorReset)
        fmt.Println("  " + colorDim + "└──────────────────────────────────────────┘" + colorReset)
}

func showMenu() {
        fmt.Println()
        fmt.Println("  " + colorBold + "[1]" + colorReset + " 📥 安装环境      " + colorGray + "首次使用必选 (安装 + 初始化工作区)" + colorReset)
        fmt.Println("  " + colorBold + "[2]" + colorReset + " 🚀 启动 QwenPaw  " + colorGray + "在线/离线模式启动" + colorReset)
        fmt.Println("  " + colorBold + "[3]" + colorReset + " 📦 模型管理      " + colorGray + "下载/导入/删除本地模型" + colorReset)
        fmt.Println("  " + colorBold + "[4]" + colorReset + " 🔄 更新          " + colorGray + "更新 QwenPaw + modelscope + uv" + colorReset)
        fmt.Println("  " + colorBold + "[5]" + colorReset + " 🔀 数据迁移      " + colorGray + "从旧版 Q-Paw 合并数据" + colorReset)
        fmt.Println("  " + colorBold + "[6]" + colorReset + " ⚙️  配置          " + colorGray + "编辑 API Key / 运行模式等" + colorReset)
        fmt.Println("  " + colorBold + "[7]" + colorReset + " 🧹 清理          " + colorGray + "清理缓存和临时文件" + colorReset)
        fmt.Println()
        fmt.Println("  " + colorDim + "[0] 退出" + colorReset)
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

        // Check if workspace is initialized
        configJsonPath := filepath.Join(usbRoot, "data", "config.json")
        if !fileExists(configJsonPath) {
                fmt.Println("  " + colorRed + "[!] 工作区未初始化！请先运行 [1] 安装环境" + colorReset)
                fmt.Println("      或手动执行: set QWENPAW_WORKING_DIR=" + filepath.Join(usbRoot, "data") + " && python -m qwenpaw init --defaults")
                fmt.Println()
                readInput("  按回车继续...")
                return
        }

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
                content := "# Q-Paw 便携模式配置\nQP_PORTABLE_MODE=1\nQP_MODEL_MODE=online\nQP_TOOL_GUARD=1\nQP_FILE_GUARD=1\nQP_SKILL_SCAN=1\n"
                os.WriteFile(envPath, []byte(content), 0644)
        }

        for {
                fmt.Println("  配置项:")
                fmt.Println("    " + colorBold + "[1]" + colorReset + " 切换运行模式 (在线/离线)")
                fmt.Println("    " + colorBold + "[2]" + colorReset + " 配置 API Key")
                fmt.Println("    " + colorBold + "[3]" + colorReset + " 查看当前配置")
                fmt.Println("    " + colorDim + "[0] 返回" + colorReset)
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
                fmt.Println("  " + colorOrange + "✅ 已切换到离线模式" + colorReset)
        } else {
                content = strings.Replace(content, "QP_MODEL_MODE=local", "QP_MODEL_MODE=online", 1)
                fmt.Println("  " + colorGreen + "✅ 已切换到在线模式" + colorReset)
        }
        os.WriteFile(envPath, []byte(content), 0644)
        readInput("  按回车继续...")
}

func configAPI(usbRoot string, envPath string) {
        fmt.Println("\n  选择 API 提供商:")
        fmt.Println("    " + colorBold + "[1]" + colorReset + " DashScope (阿里云百炼) — " + colorGreen + "推荐，国内直连" + colorReset)
        fmt.Println("    " + colorBold + "[2]" + colorReset + " OpenAI")
        fmt.Println("    " + colorBold + "[3]" + colorReset + " OpenRouter")
        fmt.Println("    " + colorBold + "[4]" + colorReset + " ModelScope (魔搭)")
        fmt.Println("    " + colorDim + "[0] 返回" + colorReset)
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
                fmt.Println("  " + colorRed + "[!] API Key 不能为空" + colorReset)
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
        fmt.Println("  " + colorGreen + "✅ API 配置已保存!" + colorReset)
        readInput("  按回车继续...")
}

func showConfig(envPath string) {
        data, err := os.ReadFile(envPath)
        if err != nil {
                fmt.Println("  [!] 无法读取配置文件")
                return
        }
        fmt.Println()
        fmt.Println("  " + colorDim + "┌─ 当前配置 ────────────────────────────────┐" + colorReset)
        for _, line := range strings.Split(string(data), "\n") {
                trimmed := strings.TrimSpace(line)
                if trimmed == "" {
                        continue
                }
                if strings.HasPrefix(trimmed, "#") {
                        continue
                }
                // Mask API key values
                if strings.HasPrefix(trimmed, "QP_API_KEY=") {
                        parts := strings.SplitN(trimmed, "=", 2)
                        if len(parts) == 2 && len(parts[1]) > 8 {
                                masked := parts[1][:4] + "****" + parts[1][len(parts[1])-4:]
                                fmt.Printf("  "+colorDim+"│"+colorReset+"  %s=%s\n", colorBold+parts[0]+colorReset, masked)
                                continue
                        }
                }
                fmt.Printf("  "+colorDim+"│"+colorReset+"  %s\n", trimmed)
        }
        fmt.Println("  " + colorDim + "└──────────────────────────────────────────┘" + colorReset)
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
                fmt.Printf("  " + colorRed + "[!] 脚本未找到: %s" + colorReset + "\n", script)
                readInput("  按回车继续...")
                return
        }

        var cmd *exec.Cmd
        if runtime.GOOS == "windows" {
                cmd = exec.Command("cmd", "/C", script)
        } else {
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

        // After batch script finishes, restore console colors
        setConsoleColor()
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
                // Fill console with white background + black text
                stdoutHandle, _, _ := procGetStdHandle.Call(uintptr(0xFFFFFFF5))
                fillConsole(stdoutHandle)
                // Move cursor to 0,0
                coord := uint32(0)
                setCCP := kernel32.NewProc("SetConsoleCursorPosition")
                setCCP.Call(stdoutHandle, uintptr(unsafe.Pointer(&coord)))
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
