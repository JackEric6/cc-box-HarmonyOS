# 影视仓 (Yingshicang)

面向 HarmonyOS NEXT 的原生视频聚合播放应用，使用 ArkTS / ArkUI 编写，支持手机、平板与 2in1 设备。

## 功能概览

- 首页推荐、分类筛选、搜索、收藏、观看历史
- 多种在线订阅源解析（JSON / XML / JS）
- 直播频道，支持超时换线路、画面比例切换
- 剧集详情、多线路、多剧集切换
- 弹幕与字幕（可调字号、透明度、延迟）
- 网盘资源识别与二次解析（可选）
- 支持深色/浅色/跟随系统
- 手机竖屏、平板/2in1 横屏自适应布局

## 目录结构

```
entry/src/main/ets/
  api/            数据源解析与播放接口
  components/     通用 UI 组件（弹幕、字幕、图片等）
  data/           本地数据库（收藏、历史等）
  model/          数据模型
  pages/          页面（首页、播放、直播、搜索、设置等）
  util/           工具方法
  utils/          设计系统、偏好存储、导航等
  viewmodel/      业务视图模型
```

## 编译

- DevEco Studio 5.0 以上
- HarmonyOS SDK 6.1.1(24)
- 打开工程根目录 `TVBoxHarmony`，同步依赖后 `Build → Build Hap(s)/APP(s)` 即可

命令行构建：

```powershell
hvigorw --no-daemon assembleHap
```

## 签名与本地构建

仓库中的 `build-profile.json5` 已移除个人证书路径和签名密码。clone 后请按下面的步骤在 DevEco Studio 中重新配置：

1. 打开 `File → Project Structure → Signing Configs`，勾选 `Automatically generate signature`，或手动选择你自己的 `.p12` / `.cer` / `.p7b`。
2. 如果使用 Release 证书，把生成的 `storePassword` / `keyPassword` 回填到 `build-profile.json5`，并确保这些值只保留在本地，不提交到仓库。
3. 私钥、证书和 Profile 文件统一放到 `signature/`，该目录已配置忽略实际密钥文件，只保留说明文档。

## 订阅地址

在「设置 → 数据源 → 配置地址」中填入订阅 JSON 地址即可加载源。首页会展示第一个可用源的分类和推荐内容，可在设置里切换默认源。

## 说明

- 本应用不内置任何视频源，全部内容来自用户自行填写的第三方订阅地址。
- 请遵守当地法律法规与订阅源的服务条款。
- 播放遇到问题时可在「设置 → 关于」内查看版本信息，并按需向源提供方反馈。

## License

本项目采用 [Apache License 2.0](LICENSE)。
