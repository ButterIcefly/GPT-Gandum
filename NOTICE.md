# 声明

## 与任何公司无关联

本项目是**非官方**的个人作品，与 **OpenAI**、**万代（BANDAI）**、**日升（SUNRISE）**、**Apple** 均无关联，未获得也未寻求任何一方的认可或赞助。

## MIT 许可覆盖什么

[LICENSE](LICENSE) 中的 MIT 许可适用于本仓库的**代码**：

- `layers/` 下的样式层
- `bake.mjs` / `verify-skin.mjs`
- `runtime/` 下的脚本
- `.command` 安装脚本与文档

它**不授予**以下任何权利：

- OpenAI / Codex 的商标、产品名、logo
- Codex 官方应用程序本体
- **`theme/` 下的壁纸图片**
- 任何角色形象、作品美术、第三方图片

## 关于壁纸素材

`theme/` 下的默认壁纸是 **RX-78-2 实体像的照片**。RX-78-2 是万代 / 日升拥有版权的角色形象。

- 本项目是**非商业同人作品**，作者出于个人爱好制作并分享。
- 图片**不适用** MIT 许可，也不随代码一并授权给你。
- **不要将本仓库的素材用于商业用途。**
- 如果你要基于本项目做自己的发行版，请用 `换壁纸.command` 换成你有权使用的图片。

如版权方认为本项目的素材使用不当，请提 issue 或直接联系作者，我会立即移除。

## 上游引擎

注入引擎来自 [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin)（MIT）。
`layers/_engine-base.css` 与 `runtime/renderer-inject.js` 基于其代码修改，原许可与版权声明随附于上游仓库。

本项目不重新分发 Node.js。运行时使用的是 Codex 桌面端自带、已由 OpenAI 签名的 Node 可执行文件。

## 安全说明

皮肤通过 Chrome DevTools 协议注入，**仅监听本机回环地址**（127.0.0.1:9341）。

皮肤启用期间，请把这个本地调试端口视为敏感资源：不要同时运行来路不明的本地程序，它们理论上可以连上这个端口操纵你的 Codex 窗口。用 `卸载还原.command` 可以彻底关掉端口和注入链路。
