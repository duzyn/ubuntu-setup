# 工作计划：重构 3rd.sh 以符合 AGENTS.md 规范

## 概述

根据 AGENTS.md 文档要求，需要重构 `3rd.sh` 的命令行接口，使其完全符合文档定义的命令格式。

## 当前问题

| 文档要求 | 当前实现 | 状态 |
|---------|---------|------|
| `bash 3rd.sh help` | `-h, --help` | ❌ 不符合 |
| `bash 3rd.sh install --deb [app]` | `--deb [app]` (无 install) | ❌ 不符合 |
| `bash 3rd.sh install --appimage [app]` | `--appimage [app]` (无 install) | ❌ 不符合 |
| `bash 3rd.sh list` | `--list` | ❌ 不符合 |
| `bash 3rd.sh list --installed` | 不存在 | ❌ 缺失 |
| `bash 3rd.sh list --outdated` | 不存在 (用 --check) | ❌ 不符合 |
| `bash 3rd.sh upgrade` | 不存在 | ❌ 缺失 |
| `bash 3rd.sh install [app]` 不指定类型应报错 | 允许默认类型 | ❌ 不符合 |

## 修改计划

### 任务 1: 重构 usage 函数

**文件**: `3rd.sh` (行 257-283)

**当前代码**:
```bash
usage() {
  echo "Usage: $0 [options] [app_name]"
  echo ""
  echo "Options:"
  echo "  --check                  Check installed apps for updates"
  echo "  --install <app_name>     Install specific app"
  echo "  --deb <app_name>         Install deb package (using apt install)"
  echo "  --appimage <app_name>    Install AppImage package (using gear-lever)"
  echo "  --dry-run                Simulate installation without actually installing"
  echo "  --list                   List all available applications"
  echo "  -h, --help               Display this help message"
  ...
}
```

**修改为**:
```bash
usage() {
  echo "Usage: $0 <command> [options]"
  echo ""
  echo "Commands:"
  echo "  help                              Show this help message"
  echo "  install --deb <app>               Install deb package"
  echo "  install --appimage <app>          Install AppImage package"
  echo "  install --deb <app> --dry-run     Simulate deb installation"
  echo "  install --appimage <app> --dry-run Simulate AppImage installation"
  echo "  list                              List all apps in versions.json"
  echo "  list --installed                  List installed apps"
  echo "  list --outdated                   List installed apps that need update"
  echo "  upgrade                           Upgrade all outdated apps"
  echo ""
  echo "Examples:"
  echo "  $0 help                           # Show help"
  echo "  $0 install --deb cherry-studio    # Install cherry-studio with deb"
  echo "  $0 install --appimage aya         # Install aya with AppImage"
  echo "  $0 list                           # List all available apps"
  echo "  $0 list --installed               # List installed apps"
  echo "  $0 list --outdated                # List apps that need update"
  echo "  $0 upgrade                        # Upgrade all outdated apps"
}
```

---

### 任务 2: 完全重写参数解析逻辑

**文件**: `3rd.sh` (行 332-420)

**当前代码**: 使用 `--check`, `--list`, `--install`, `--deb`, `--appimage` 等选项

**修改为** (使用子命令模式):

```bash
# Parse arguments
FORMAT=""
APP_NAME=""
COMMAND=""
DRY_RUN=false
LIST_MODE=""  # "", "installed", "outdated"

# First argument is the command
if [ $# -eq 0 ]; then
  usage
  exit 0
fi

COMMAND="$1"
shift

case "$COMMAND" in
  help|-h|--help)
    usage
    exit 0
    ;;
  
  install)
    # Must specify --deb or --appimage
    if [ $# -eq 0 ]; then
      echo -e "${RED}Error: Please specify --deb or --appimage${NC}"
      usage
      exit 1
    fi
    
    case "$1" in
      --deb)
        FORMAT="deb"
        shift
        ;;
      --appimage)
        FORMAT="appimage"
        shift
        ;;
      *)
        echo -e "${RED}Error: Must specify --deb or --appimage${NC}"
        usage
        exit 1
        ;;
    esac
    
    # Parse remaining arguments
    while [ $# -gt 0 ]; do
      case "$1" in
        --dry-run)
          DRY_RUN=true
          shift
          ;;
        -*)
          echo -e "${RED}Error: Unknown option $1${NC}"
          usage
          exit 1
          ;;
        *)
          if [ -z "$APP_NAME" ]; then
            APP_NAME="$1"
          fi
          shift
          ;;
      esac
    done
    
    if [ -z "$APP_NAME" ]; then
      echo -e "${RED}Error: Please specify application name${NC}"
      usage
      exit 1
    fi
    ;;
  
  list)
    # Check for subcommand
    if [ $# -gt 0 ]; then
      case "$1" in
        --installed)
          LIST_MODE="installed"
          shift
          ;;
        --outdated)
          LIST_MODE="outdated"
          shift
          ;;
        *)
          echo -e "${RED}Error: Unknown option $1${NC}"
          usage
          exit 1
          ;;
      esac
    fi
    ;;
  
  upgrade)
    # Upgrade all outdated apps
    ;;
  
  *)
    echo -e "${RED}Error: Unknown command '$COMMAND'${NC}"
    usage
    exit 1
    ;;
esac
```

---

### 任务 3: 重构 list_apps 函数

**文件**: `3rd.sh` (行 284-328)

**当前代码**: 简单列表输出

**修改为**: 表格格式，DEB在前，AppImage在后，按字母排序

```bash
# List all applications with status
list_apps() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
  fi
  
  echo "Available applications list:"
  echo ""
  printf "%-25s %-10s %-12s %-15s\n" "软件名" "类型" "状态" "最新版本"
  printf "%s\n" "-------------------------------------------------------------------------"
  
  # Get sorted DEB apps
  local deb_apps
  deb_apps=$(jq -r 'to_entries[] | select(.value.format == "deb") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Get sorted AppImage apps
  local appimage_apps
  appimage_apps=$(jq -r 'to_entries[] | select(.value.format == "appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Process DEB apps first
  for app_name in $deb_apps; do
    local pkg_keyword available_version status
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    available_version=$(jq -r ".\"$app_name\".version // \"unknown\"" "$CONFIG_FILE")
    
    # Check status
    if dpkg-query -W "$pkg_keyword" &>/dev/null; then
      status="installed"
    else
      status="not installed"
    fi
    
    printf "%-25s %-10s %-12s %-15s\n" "$app_name" "DEB" "$status" "$available_version"
  done
  
  # Process AppImage apps
  for app_name in $appimage_apps; do
    local pkg_keyword available_version status
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    available_version=$(jq -r ".\"$app_name\".version // \"unknown\"" "$CONFIG_FILE")
    
    # Check status
    if [ -f "$HOME/AppImages/${pkg_keyword}.appimage" ]; then
      status="installed"
    else
      status="not installed"
    fi
    
    printf "%-25s %-10s %-12s %-15s\n" "$app_name" "AppImage" "$status" "$available_version"
  done
}
```

---

### 任务 4: 添加 list_installed 和 list_outdated 函数

**新增函数**:

```bash
# List installed apps only
list_installed() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
  fi
  
  echo "Installed applications:"
  echo ""
  printf "%-25s %-10s %-15s\n" "软件名" "类型" "当前版本"
  printf "%s\n" "--------------------------------------------------------"
  
  local has_installed=0
  
  # Get sorted DEB apps
  local deb_apps
  deb_apps=$(jq -r 'to_entries[] | select(.value.format == "deb") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Get sorted AppImage apps
  local appimage_apps
  appimage_apps=$(jq -r 'to_entries[] | select(.value.format == "appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Process DEB apps first
  for app_name in $deb_apps; do
    local pkg_keyword installed_version
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    
    if dpkg-query -W "$pkg_keyword" &>/dev/null; then
      installed_version=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null || echo "unknown")
      printf "%-25s %-10s %-15s\n" "$app_name" "DEB" "$installed_version"
      has_installed=1
    fi
  done
  
  # Process AppImage apps
  for app_name in $appimage_apps; do
    local pkg_keyword
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    
    if [ -f "$HOME/AppImages/${pkg_keyword}.appimage" ]; then
      printf "%-25s %-10s %-15s\n" "$app_name" "AppImage" "installed"
      has_installed=1
    fi
  done
  
  if [ $has_installed -eq 0 ]; then
    echo "No apps installed."
  fi
}

# List outdated apps
list_outdated() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
  fi
  
  echo "Apps that need updates:"
  echo ""
  printf "%-25s %-10s %-35s\n" "软件名" "类型" "版本"
  printf "%s\n" "----------------------------------------------------------------------"
  
  local has_outdated=0
  
  # Get sorted DEB apps
  local deb_apps
  deb_apps=$(jq -r 'to_entries[] | select(.value.format == "deb") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Get sorted AppImage apps
  local appimage_apps
  appimage_apps=$(jq -r 'to_entries[] | select(.value.format == "appimage") | .key' "$CONFIG_FILE" | sort)
  
  # Process DEB apps first
  for app_name in $deb_apps; do
    local pkg_keyword available_version result
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    available_version=$(jq -r ".\"$app_name\".version // \"unknown\"" "$CONFIG_FILE")
    
    result=0
    check_deb_update "$pkg_keyword" "$available_version" || result=$?
    
    if [ $result -eq 2 ]; then
      local installed_version
      installed_version=$(dpkg-query -W -f='${Version}\n' "$pkg_keyword" 2>/dev/null | sed 's/-.*//' || echo "unknown")
      printf "%-25s %-10s %-35s\n" "$app_name" "DEB" "($installed_version -> $available_version)"
      APPS_TO_UPDATE+=("$app_name")
      has_outdated=1
    fi
  done
  
  # AppImage 版本检测暂不支持，只显示已安装的
  
  if [ $has_outdated -eq 0 ]; then
    echo "All installed apps are up to date."
  fi
}
```

---

### 任务 5: 添加 upgrade 命令

**修改 check_all_updates 函数为 upgrade_apps**:

```bash
upgrade_apps() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
    exit 1
  fi
  
  install_dependencies
  
  echo -e "${BLUE}====== Checking for outdated apps ======${NC}"
  echo ""
  
  # First, find all outdated apps
  local deb_apps appimage_apps
  
  deb_apps=$(jq -r 'to_entries[] | select(.value.format == "deb") | select(.key != "gear-lever-appimage") | .key' "$CONFIG_FILE" | sort)
  
  for app_name in $deb_apps; do
    local pkg_keyword available_version result
    
    pkg_keyword=$(jq -r ".\"$app_name\".package_keyword // \"\"" "$CONFIG_FILE")
    available_version=$(jq -r ".\"$app_name\".version // \"unknown\"" "$CONFIG_FILE")
    
    result=0
    check_deb_update "$pkg_keyword" "$available_version" || result=$?
    
    if [ $result -eq 2 ]; then
      APPS_TO_UPDATE+=("$app_name")
    fi
  done
  
  if [ ${#APPS_TO_UPDATE[@]} -eq 0 ]; then
    echo -e "${GREEN}All installed apps are up to date!${NC}"
    exit 0
  fi
  
  echo -e "${RED}Found ${#APPS_TO_UPDATE[@]} apps that need updates:${NC}"
  for app in "${APPS_TO_UPDATE[@]}"; do
    echo "  - $app"
  done
  
  echo ""
  echo -n "Do you want to update these apps? [y/N]: "
  read -r response
  
  if [[ "$response" =~ ^[Yy]$ ]]; then
    for app in "${APPS_TO_UPDATE[@]}"; do
      echo ""
      echo -e "${BLUE}====== Updating: $app ======${NC}"
      # 递归调用自身进行安装
      "$0" install --deb "$app"
    done
  else
    echo "Skipped."
  fi
}
```

---

### 任务 6: 更新执行命令部分

**文件**: `3rd.sh` (行 420-613)

**修改为**:

```bash
# Execute command
case "$COMMAND" in
  list)
    if [ "$LIST_MODE" = "" ]; then
      list_apps
    elif [ "$LIST_MODE" = "installed" ]; then
      list_installed
    elif [ "$LIST_MODE" = "outdated" ]; then
      list_outdated
    fi
    exit 0
    ;;
  upgrade)
    upgrade_apps
    exit 0
    ;;
  install)
    # Check configuration file
    if [ ! -f "$CONFIG_FILE" ]; then
      echo -e "${RED}Error: Configuration file $CONFIG_FILE not found${NC}"
      exit 1
    fi
    
    if [ "$DRY_RUN" != true ]; then
      install_dependencies
    fi
    
    # Check if application exists
    if ! jq -e "has(\"$APP_NAME\")" "$CONFIG_FILE" &>/dev/null; then
      echo -e "${RED}Error: Application '$APP_NAME' not found${NC}"
      echo -e "${YELLOW}Use '$0 list' to view all available applications${NC}"
      exit 1
    fi
    
    # ... rest of install logic (keep existing)
    ;;
esac
```

---

## 测试计划

### 测试用例

| 测试 | 命令 | 预期结果 |
|------|------|----------|
| help | `bash 3rd.sh help` | 显示帮助信息 |
| install deb | `bash 3rd.sh install --deb cherry-studio` | 安装 cherry-studio |
| install appimage | `bash 3rd.sh install --appimage aya` | 安装 aya |
| install 无类型 | `bash 3rd.sh install cherry-studio` | 报错：必须指定 --deb 或 --appimage |
| list | `bash 3rd.sh list` | 显示所有已收录的 app |
| list --installed | `bash 3rd.sh list --installed` | 显示已安装的 app |
| list --outdated | `bash 3rd.sh list --outdated` | 显示需要更新的 app |
| upgrade | `bash 3rd.sh upgrade` | 升级所有需要更新的 app |
| dry-run | `bash 3rd.sh install --deb test --dry-run` | 模拟安装 |

---

## 编码规范提醒

- 所有文件使用 LF 换行
- 所有文件按 2 空格缩进
- 使用 bats 测试框架编写单元测试
- 测试安装时使用 --dry-run 参数避免下载大量包

---

## 执行建议

建议使用 Sisyphus 或其他实现代理来执行此计划。使用以下命令：

```bash
# 查看计划
cat .sisyphus/plans/3rd-sh-refactor.md

# 执行实现
# 由 Sisyphus 代理执行实际的代码修改
```
