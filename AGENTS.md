# AGENTS.md

**Generated:** 2025-04-05
**Commit:** 0d69894
**Branch:** main

Linux Mint 初始化设置脚本集 - 自动化安装 DEB、AppImage 包及系统配置。

## STRUCTURE

```
./
├── setup.sh           # 主入口：系统初始化编排
├── 3rd.sh             # 第三方包管理器 (DEB/AppImage)
├── update_versions.py # 版本抓取器 (apps.json → versions.json)
├── apps.json          # 包定义配置
├── versions.json      # 生成的最新版本数据
├── 0-locale.sh        # 时区/语言设置
├── 1-apt.sh           # APT 包安装
├── 2-brew.sh          # Homebrew 安装（阿里云镜像）
├── 4-nodejs.sh        # Node.js/nvm 安装
├── 9-optional.sh      # 可选组件
├── check-version.sh   # 系统版本检查
├── locale/            # 输入法/语言脚本
├── terminal/          # 终端工具脚本
└── themes/            # 主题配置脚本
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| 安装第三方 DEB/AppImage | `3rd.sh` | 独立入口，不通过 setup.sh |
| 更新软件版本数据 | `update_versions.py apps.json` | 生成 versions.json |
| 配置新软件包 | `apps.json` | 定义包名、版本获取方式 |
| 系统初始化流程 | `setup.sh` | 仅执行基础设置 |
| 运行测试 | `bash test_3rd.sh` | 自定义测试框架 |
| 安装测试 (--dry-run) | `bash 3rd.sh install --deb <app> --dry-run` | 避免下载流量 |

## ENTRY POINTS

| Script | Purpose |
|--------|---------|
| `setup.sh` | 主初始化入口 (check-version + 0-locale) |
| `3rd.sh` | 第三方包管理 CLI |
| `update_versions.py` | 版本数据更新工具 |

## CONVENTIONS

- **Line endings**: LF (Unix)
- **Indent**: 2 spaces
- **Testing**: Shell 脚本需单元测试 (AGENTS.md 指定 bats，实际使用自定义框架)
- **TDD**: 脚本自测通过才算完成
- **Dry-run**: 测试安装时使用 `--dry-run` 避免流量消耗

## ANTI-PATTERNS (THIS PROJECT)

| Pattern | Why Forbidden |
|---------|---------------|
| `bash 3rd install <app>` | 必须指定 `--deb` 或 `--appimage` |
| `bash 3rd.sh <unknown-cmd>` | 命令需明确支持 |
| 直接运行 numbered scripts | 应通过 setup.sh 或按需单独执行 |

## COMMANDS

```bash
# 系统初始化 (Linux Mint 22 only)
bash setup.sh

# 安装 Homebrew（阿里云镜像）
bash 2-brew.sh

# 第三方包管理
bash 3rd.sh help                    # 查看帮助
bash 3rd.sh list                    # 列出所有可用应用
bash 3rd.sh list --installed        # 列出已安装
bash 3rd.sh list --outdated         # 列出可更新
bash 3rd.sh install --deb <app>     # 安装 DEB 包
bash 3rd.sh install --appimage <app> # 安装 AppImage
bash 3rd.sh upgrade                 # 升级所有应用

# 测试 (dry-run 避免下载)
bash 3rd.sh install --deb cherry-studio --dry-run

# 版本数据更新
python3 update_versions.py apps.json

# 运行单元测试
bash test_3rd.sh
```

## NOTES

- **Dual Workflow**: setup.sh 系统初始化 与 3rd.sh 包管理 是独立的两套流程
- **CI/CD**: `.github/workflows/check_versions.yml` 每小时自动更新 versions.json
- **Gear-Lever**: AppImage 安装依赖 gear-lever 工具
- **测试现状**: AGENTS.md 指定 bats 框架，实际 test_3rd.sh 使用自定义框架
