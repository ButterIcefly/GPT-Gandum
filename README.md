# 🌠 GPT-skin-Gundam · Windows 

<p align="center">
  <em>为 GPT 客户端注入  高达 主题皮肤的第三方运行时适配层</em>
</p>

<p align="center">
  <img alt="Platform" src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white">
  <img alt="Type" src="https://img.shields.io/badge/Type-第三方皮肤-orange?style=for-the-badge">
  <img alt="Status" src="https://img.shields.io/badge/Status-非官方-lightgrey?style=for-the-badge">
</p>

---

## 📸 预览

<p align="center">
  <img width="100%" alt="首页效果" src="https://github.com/user-attachments/assets/cbc0b05c-fc98-41b0-9339-43e00cc9999a" />
  <br><sub>首页效果</sub>
</p>

<p align="center">
  <img width="100%" alt="其他页面" src="https://github.com/user-attachments/assets/e52a367c-d6a3-4af4-a063-e82a3960690d" />
  <br><sub>其他页面</sub>
</p>

---

## 📖 简介

`GPT-skin-Gundam` 是一套面向 Windows 的第三方运行时皮肤方案。便携发行包无需额外安装依赖，解压后双击 `INSTALL.cmd` 即可完成部署；安装完成后，解压目录可以直接删除，不影响皮肤的持续运行。

## 🧩 安装器做什么 / 不做什么

**✅ 只会**

| 步骤 | 说明 |
|:---:|---|
| 1️⃣ | 将皮肤资源复制到 `%LOCALAPPDATA%\CodexDreamSkinGundam` |
| 2️⃣ | 使用本机回环调试端口启动 GPT |
| 3️⃣ | 通过 Chrome DevTools Protocol 向主窗口注入 CSS |
| 4️⃣ | 创建当前用户的登录自启动项 |
| 5️⃣ | 附带完整卸载脚本，随时可还原 |

**🚫 从不**

- 修改或解包 GPT 的 `app.asar`
- 覆盖 Microsoft Store / MSIX 安装目录中的任何文件

---

## 🚀 快速开始

1. 下载并解压便携发行包
2. 双击 `INSTALL.cmd`
3. 等待脚本完成安装、启动与校验
4. 安装完成后，可删除解压目录

---

## 📂 文件说明

| 文件 | 作用 |
|---|---|
| `Install-Skin.ps1` | 安装、启动并验证皮肤 |
| `Start-Skin.ps1` | 以皮肤模式启动 Codex，并保持样式注入 |
| `Inject-Skin.ps1` | 注入器，仅访问 `127.0.0.1` |
| `Verify-Skin.ps1` | 检查页面中的皮肤标记与首页输入框 |
| `Uninstall-Skin.ps1` | 删除自启动项与独立状态目录，恢复默认启动 |
| `Test-Skin.ps1` | 离线静态检查 |
| `INSTALL.cmd` | 便携包一键安装入口 |
| `UNINSTALL.cmd` | 一键停止并彻底删除皮肤 |

---

## ⚠️ 风险与边界

> [!WARNING]
> - 这是非官方运行时定制，Codex 更新后 DOM 结构变化可能导致样式失效
> - 调试端口仅绑定 `127.0.0.1`，不会监听局域网接口
> - 安装 / 卸载都需要重启 Codex，会中断正在运行的本地任务，请先保存工作
> - Store 更新可能改变可执行文件路径，启动器每次都会重新查询当前安装包

---

## 🗑️ 卸载

双击 `UNINSTALL.cmd`，脚本会自动停止皮肤注入、删除自启动项与独立状态目录，将客户端恢复为默认启动状态。

---

## 📌 免责声明

> [!IMPORTANT]
> 这是个人制作的非官方主题，不代表 Gundam 版权方、OpenAI 或 Codex++ 官方立场，未获得其官方授权。
> 完整皮肤效果依赖第三方增强工具，安装后可能修改客户端文件与代码签名，请自行评估风险后使用。

---
------------------------------------------------------------------------

<div align="center">

### 🎉 感谢使用 GPT-Gandum！

如果这个项目对你有帮助，欢迎 ⭐ Star 和 🍴 Fork！

**Made with ❤️ by [fenyr]**

</div>
