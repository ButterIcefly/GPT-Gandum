# GPT-skin-Gundam for Windows
<img width="2560" height="1393" alt="首页效果" src="https://github.com/user-attachments/assets/cbc0b05c-fc98-41b0-9339-43e00cc9999a" />

<img width="2560" height="1391" alt="其他页面" src="https://github.com/user-attachments/assets/e52a367c-d6a3-4af4-a063-e82a3960690d" />


这是 `GPT-skin-Gundam` 的 Windows 运行时适配层。便携发行包解压后双击
`INSTALL.cmd` 即可；安装完成后，解压目录可以删除。

它不会修改或解包 GPT 的 `app.asar`，也不会覆盖 Microsoft Store / MSIX 安装目录中的任何文件。安装器只会：

1. 把皮肤资源复制到 `%LOCALAPPDATA%\CodexDreamSkinGundam`；
2. 用本机回环调试端口启动 GPT；
3. 通过 Chrome DevTools Protocol 向主窗口注入 CSS；
4. 创建当前用户的登录自启动项；
5. 提供完整卸载脚本。
   
提醒：这是个人制作的非官方主题，不代表 Chiikawa 版权方、OpenAI 或 Codex++ 官方授权。完整皮肤依赖第三方增强工具，可能修改客户端文件和代码签名。
## 文件

- `Install-Skin.ps1`：安装、启动并验证皮肤。
- `Start-Skin.ps1`：以皮肤模式启动 Codex，并保持注入。
- `Inject-Skin.ps1`：注入器；只访问 `127.0.0.1`。
- `Verify-Skin.ps1`：直接检查页面中的皮肤标记和首页输入框。
- `Uninstall-Skin.ps1`：删除自启动项和独立状态目录，恢复正常启动。
- `Test-Skin.ps1`：离线静态检查。
- `INSTALL.cmd`：便携包的一键安装入口。
- `UNINSTALL.cmd`：一键停止并彻底删除皮肤。

## 风险边界

- 这是非官方运行时定制，Codex 更新后 DOM 变化可能导致样式失效。
- 调试端口仅绑定 `127.0.0.1`，不会监听局域网接口。
- 安装/卸载需要重启 Codex，会中断正在运行的本地任务；请先保存工作。
- Store 更新可能改变可执行文件路径，启动器每次都会重新查询当前安装包。
