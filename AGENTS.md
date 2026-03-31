# AGENTS.md

一个用于初始化设置 Linux Mint 的脚本软件。

## 安装 APT 中没有的第三方 DEB 和 AppImage 包

文件的作用：

- apps.json: 用于配置要安装的 DEB 和 AppImage 包，需配置包名、获取软件版本的方式
- versions.json：记录软件最新版本的信息记录，用于后续更新 app 用
- update_version.py：解析 apps.json 后获得的软件最新版本的信息
  记录，生成 versions.json
- 3rd.sh: 解析 versions.json，安装、升级 app

3rd.sh 用法如下：

- bash 3rd.sh help：查看帮助
- bash 3rd.sh install --deb [app]: 显示指定只安装 deb app，如果无，则报错
- bash 3rd.sh install --appimage [app]: 显示指定只安装 appimage app，如果无，则报错
- bash 3rd.sh install [app] --dry-run：模拟安装，而不实际下载包，用于测试用，避免流量消耗
- bash 3rd.shlist: 展示 versions.json 中已收录的所有 app 输出格式如下

    | 软件名 | 类型 | 最新版本 |
    | ----- | ---- | ------ |
    | ghostty | DEB | 1.3.1 |
    | Todoist | AppImage | 1.2.1 |

    其中 DEB 包排前面，AppImage 排后面，每个类别下的软件都按包名以数字、字母顺序排列

- bash 3rd.sh list --installed: 展示已安装的 app，排序规则如上
- bash 3rd.sh list --outdated: 展示已安装的但是不是最新版本 app，排序规则如上
- bash 3rd.sh upgrade：升级所有不是最新版本的 app

错误的用法：

- bash 3rd install [app]：未指定 app 类型
- bash 3rd.sh command: 不支持的命令。

要安装 AppImage 的包，需要先安装 gear-lever-appimage，然后用 `gear-lever
--integrate [appimage_file]` 来安装 AppImage app 

## 编码规范

- 所有文件使用 LF 换行
- 所有文件按 2 空格缩进
- Shell 脚本要写单元测试脚本，使用 bats 测试框架
- TTD 开发模式，写完的脚本要自测通过，才能完成任务
- 测试安装时，使用 --dry-run 参数来避免下载大量的包，耗费流量
