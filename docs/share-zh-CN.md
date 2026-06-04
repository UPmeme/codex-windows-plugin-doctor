# Windows 上 Codex Computer Use 插件不可用？我做了个诊断/修复工具

最近 Windows 版 Codex Desktop 的 Computer Use、Chrome、Browser 插件问题比较常见：

```text
Computer Use 在设置里看起来已经安装，
但在对话里 @computer 没有出现桌面控制工具。
```

还有一种相关情况：

```text
Chrome 插件显示 Connected，
但 Codex 仍然不能控制 Chrome。
```

我做了一个开源工具：

https://github.com/UPmeme/codex-windows-plugin-doctor

它的目标不是盲目删除 `.codex` 或重装所有东西，而是先把问题分层诊断清楚：

- Codex `config.toml` 是否存在。
- Browser / Chrome / Computer Use 是否在配置里启用。
- OpenAI bundled marketplace 是否配置正常。
- 插件 cache 是否完整。
- Computer Use / Chrome / Browser 的 skill 文件是否存在。
- Chrome native messaging host 是否注册。
- Codex Chrome extension 是否安装。

一条命令诊断：

```powershell
.\scripts\codex-computer-use-doctor.ps1
```

查看修复计划：

```powershell
.\scripts\codex-computer-use-doctor.ps1 -Repair
```

执行保守修复：

```powershell
.\scripts\codex-computer-use-doctor.ps1 -Repair -Apply
```

默认模式是只读的，不会改 `.codex`，不会读 token，也不会清空配置。

`-Repair -Apply` 会先备份 Codex 配置，然后尝试修复 bundled plugin marketplace 和 Browser / Chrome / Computer Use 插件安装状态。

如果你也遇到 Windows 上 Codex Computer Use 或 Chrome 插件不可用的问题，可以跑一下诊断，把报告贴到这个 issue 里：

https://github.com/UPmeme/codex-windows-plugin-doctor/issues/1

注意：贴报告前请删掉 API key、OAuth token、私有仓库名、敏感路径和截图。
