# 影视仓 - 签名文件目录

**注意：本目录下的密钥文件绝对不要提交到 git 仓库！**

## 需要放入的四件套（DevEco Studio 生成或从 AGC 下载）

| 文件 | 说明 |
| --- | --- |
| `yingshicang_release.p12` | 密钥库（含私钥+证书链） |
| `yingshicang_release.cer` | 数字证书（.cer） |
| `yingshicang_release.p7b` | Profile 描述文件（AGC 后台申请后下载） |
| store/key password | 分别填入 `build-profile.json5` 的 `storePassword`/`keyPassword`（加密后的密文） |

## 生成流程（DevEco Studio）

1. 菜单：`Build → Generate Key and CSR`
   - Store File: 选择本目录，命名 `yingshicang_release.p12`
   - Key Alias: `yingshicang_release`
   - Validity: 25 年
   - 填写 CN/OU/O/L/ST/C
2. 生成 CSR 后：菜单 `Build → Generate Key and CSR → Next`，导出 `.csr`
3. 登录 [AGC](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)：
   - 项目设置 → 我的项目 → 影视仓 (`com.yingshicang.app`)
   - 上传 `.csr` → 下载 `.cer` 数字证书
   - 应用签名 → 创建 Release Profile（HarmonyOS）→ 下载 `.p7b`
4. 把 `.p12`/`.cer`/`.p7b` 三个文件放到本目录
5. 打开根目录 `build-profile.json5`，把 `storePassword`/`keyPassword` 换成 DevEco 生成的密文
   （在 DevEco 的 `Project Structure → Signing Configs` 里填一次密码，会自动加密写入）

## Debug 签名（本地调试用）

DevEco 自动使用 `~/.ohos/config/auto_debug_*` 下的自签名，无需手动配置。