# 微影视 (TvBoxHarmony)

面向 HarmonyOS NEXT 的原生视频聚合播放应用，使用 ArkTS / ArkUI 编写，支持手机、平板与 2in1 设备。

> 应用安装后桌面显示名称为「微影视」，仓库项目名为 `TvBoxHarmony`，二者指的是同一个项目。

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

## 从源码构建（贡献者指南）

### 1. 克隆代码

```powershell
git clone https://github.com/yuppiesnotzhuhao/TvBoxHarmony.git
cd TvBoxHarmony
```

### 2. 环境要求

- DevEco Studio 5.0 及以上
- HarmonyOS SDK 6.1.1(24)，compatibleSdkVersion 6.1.0(23)
- 项目使用 ArkTS / Stage 模型，Node 由 DevEco Studio 自带

### 3. 同步依赖

用 DevEco Studio 打开工程根目录 `TVBoxHarmony`，等待 `oh_modules` 依赖自动同步完成。如果同步失败，可在终端执行：

```powershell
ohpm install
```

### 4. 配置签名

仓库中的 `build-profile.json5` 已移除个人证书和路径，直接构建会报签名相关错误。请先配置本地签名：

**方式一：自动签名（最快，适合测试）**

1. `File → Project Structure → Signing Configs`
2. 勾选 `Automatically generate signature`
3. 登录华为账号并同意，DevEco Studio 会自动生成调试证书

**方式二：手动签名（适合正式发布）**

1. 准备自己的 `.p12` / `.cer` / `.p7b` 文件
2. 在签名配置中选择对应的文件并填写别名和密码
3. 把生成的 `storePassword` / `keyPassword` 回填到 `build-profile.json5`

> 注意：签名密码、私钥、证书、Profile 文件**不要提交到 Git**。`signature/` 目录已配置忽略实际密钥文件。

### 5. 构建 Hap

**DevEco Studio 构建（推荐）**

`Build → Build Hap(s)/APP(s) → Build Hap(s)`

构建产物路径：

```
entry/build/default/outputs/default/entry-default-signed.hap
```

**命令行构建**

```powershell
.\hvigorw --no-daemon assembleHap
```

如果报 `spawn java ENOENT`，说明系统缺少 Java 环境，改用 DevEco Studio 构建即可。

### 6. 安装到设备

```powershell
hdc install entry-default-signed.hap
```

或直接在 DevEco Studio 点击运行按钮。

## 订阅地址

在「设置 → 数据源 → 配置地址」中填入订阅 JSON 地址即可加载源。首页会展示第一个可用源的分类和推荐内容，可在设置里切换默认源。

## 说明

- 本应用不内置任何视频源，全部内容来自用户自行填写的第三方订阅地址。
- 请遵守当地法律法规与订阅源的服务条款。
- 播放遇到问题时可在「设置 → 关于」内查看版本信息，并按需向源提供方反馈。

## License

本项目采用 [Apache License 2.0](LICENSE)。
