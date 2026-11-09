# 喝水提醒

一款 macOS 菜单栏小工具。打开后，每隔 30 分钟会出现全屏喝水提醒。如果连接了多台显示器，提醒会同时覆盖每块屏幕。点击「喝好了，继续」后，重新开始 30 分钟倒计时。

## 下载与使用

1. 在 [Releases](https://github.com/wangjiaxun001-ui/water-reminder-macos/releases/latest) 下载 `WaterReminder-macOS-arm64.zip`。
2. 解压后，将「喝水提醒.app」拖到「应用程序」并打开。此版本适用于配备 Apple 芯片、运行 macOS 13 或更高版本的 Mac。
3. 点击菜单栏的水滴图标，可以查看下次提醒时间、选择「现在提醒我」或退出。

发布包使用本地签名。如果 macOS 拦截首次打开，可在「系统设置」→「隐私与安全性」中确认打开。

## 从源码构建

在已安装 Xcode 命令行工具的 Mac 上，从仓库根目录运行以下命令。

```sh
app="喝水提醒.app"
mkdir -p "$app/Contents/MacOS"
swiftc -O -sdk "$(xcrun --show-sdk-path)" 源码/main.swift -o "$app/Contents/MacOS/WaterReminder"
codesign --force --sign - "$app"
open "$app"
```

## 测试

下面的命令会在独立测试进程中使用 2 秒间隔，连续检查两轮全屏显示、按钮关闭和重新计时。测试完成后自动退出。

```sh
"./喝水提醒.app/Contents/MacOS/WaterReminder" --self-test
```
