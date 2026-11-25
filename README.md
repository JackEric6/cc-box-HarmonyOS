# 丛丛影视 HarmonyOS

丛丛影视的 HarmonyOS 原生工程，应用标识为 `com.jackeric.ccbox.harmonyos`。应用使用 ArkTS、ArkUI 和 HarmonyOS Stage 模型，不是 Android APK 的改名或重新打包。

当前版本为 `0.1.0`。本工程以 [TvBoxHarmony](https://github.com/yuppiesnotzhuhao/TvBoxHarmony) 的 Apache-2.0 原生实现为基础，附带丛丛影视 Android 工程的影视源配置副本。上游来源和修改说明见 [NOTICE](NOTICE)。

## 当前能力

- 原生首页、分类、站点搜索、详情、多线路和剧集播放
- 通用 TVBox JSON/XML CMS 影视源解析
- 本地内置默认站点配置；首次启动不需要输入远程配置 JSON
- 直播、播放历史、收藏、弹幕/字幕及常规设置（以当前 ArkTS 实现为准）
- 手机、平板和横屏布局

默认站点清单位于 `entry/src/main/resources/rawfile/cc_box_sources.json`。它是随应用打包的配置文件；站点 API、海报和媒体仍由相应第三方服务提供，因此联网搜索和播放需要网络。

## 与 Android 版的差异

这不是 Android 版的完整功能等价移植。瓜子源已添加 ArkTS 原生适配：加密请求、设备 token 注册、搜索、首页/分类、详情、线路选集和播放地址解析均由应用直接请求瓜子服务，不依赖 Android 本地回环服务。荐片按项目要求不移植。当前环境未能运行 HarmonyOS 编译器或真机，因此瓜子协议的端到端 HarmonyOS 运行仍需由 GitHub Actions 和设备验证确认。

安卓端定制的西瓜 M3U8 广告识别/净化逻辑尚未迁移；西瓜当前仅使用通用 CMS 和通用 HLS 播放链路。

其他 Android 专有组件（Chaquopy、Android/JNI 播放组件及相关服务）也不能直接运行在 HarmonyOS。需要使用 HarmonyOS API 逐项重写，并在 DevEco Studio 和目标设备上验证。

## 构建

需要安装与工程 SDK 版本匹配的 DevEco Studio/HarmonyOS SDK，以及 Node.js/Hvigor/OHPM。本工程 `build-profile.json5` 使用 HarmonyOS SDK `6.1.1(24)`，调试或发布到设备还需要 DevEco Studio 配置的签名材料。

在 DevEco Studio 中打开仓库根目录并同步依赖，然后构建 `entry` HAP。也可在已正确配置 DevEco 命令行环境的终端执行：

```powershell
hvigorw --no-daemon assembleHap
```

设备安装需使用有效签名的 HAP，并通过 DevEco Studio 或 `hdc install <signed-hap>` 安装。证书、Profile、私钥和密码不得提交至仓库。

仓库包含 GitHub Actions 工作流 `.github/workflows/harmonyos-build.yml`，在推送、PR 或手动触发时使用 HarmonyOS CLI 构建 HAP，并上传构建产物。签名配置当前未包含个人证书和 Profile；CI 构建状态会在本次执行后据实记录。未验证可安装签名包前，不发布伪装成可安装包的 Release。

## 目录

```text
AppScope/                         应用标识、名称及图标
entry/src/main/ets/               ArkTS 页面、数据层、网络和播放实现
entry/src/main/resources/rawfile/ 内置 CC-BOX 站点配置
NOTICE                            上游代码及配置来源说明
```

## 许可证

本工程保留上游 [Apache License 2.0](LICENSE)。上游代码的版权与许可声明继续适用；各数据源、图标和服务由其各自权利人提供。使用者应遵守适用法律和各服务条款。
