# Codex Computer Use Windows 修复工具

诊断并修复 Windows 上 Codex Desktop 的 Computer Use、Chrome、Browser 插件不可用问题。

常见症状：

```text
Computer Use 在 Codex 设置里看起来已经安装，
但是在对话里 @computer / @Computer Use 没有出现桌面控制工具。
```

相关症状：

```text
Chrome 插件显示 Connected，
但是 Codex 不能控制 Chrome。
```

## 为什么做这个项目

Windows 上 Codex Computer Use / Chrome 插件问题通常不是单一原因。可能是：

- `config.toml` 里插件配置存在，但插件市场没有正确注册。
- 插件缓存目录不完整。
- WindowsApps 里的 bundled 插件源受保护，直接安装失败。
- Chrome native messaging host 没注册好。
- Chrome extension 装了，但 Codex 当前线程没有暴露工具。
- Codex Desktop 需要重启或新建线程才能重新挂载工具。

这个工具会先给出诊断报告，再给出修复计划。默认不改文件。

## 快速使用

诊断：

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

生成 JSON：

```powershell
.\scripts\codex-computer-use-doctor.ps1 -Json
```

保存报告：

```powershell
.\scripts\codex-computer-use-doctor.ps1 -OutFile .\reports\codex-computer-use-report.txt
```

## 它会检查什么

- Codex home 目录。
- `.codex/config.toml`。
- Browser / Chrome / Computer Use 是否在配置里。
- OpenAI bundled marketplace 是否配置。
- 插件 cache 是否存在。
- Computer Use / Chrome / Browser 的 `SKILL.md` 是否存在。
- Chrome native messaging host 注册表项。
- Codex Chrome extension 是否安装。
- 根据缺失项生成 repair plan。

## 修复模式做什么

`-Repair` 只展示修复步骤，不执行。

`-Repair -Apply` 会：

1. 备份 Codex 配置和 global state。
2. 尝试找到 Codex Desktop 自带的 `openai-bundled` 插件源。
3. 用字节流复制到用户 `.codex` 目录下，避免 WindowsApps 保护属性导致安装失败。
4. 重新注册 bundled marketplace。
5. 重新安装 Browser、Chrome、Computer Use。
6. 提示重启 Codex Desktop，并在新线程测试 `@computer`。

## 不会做什么

默认不会：

- 删除整个 `.codex`。
- 读取 token 或凭据。
- 修改浏览器登录状态。
- 绕过组织策略或产品权限。
- 清空所有插件缓存。

即使执行 `-Repair -Apply`，也会先备份，并且只做和插件市场/插件安装相关的保守修复。

## 适合发 bug report 的信息

如果修复后仍然不可用，把诊断报告贴到 issue 或社区帖子里，并说明：

- Windows 版本。
- Codex Desktop 版本。
- Computer Use 是否在设置页可见。
- `@computer` 在新线程里是否出现工具。
- Chrome 插件是否显示 Connected。
- Browser / Chrome / Computer Use 是否同时不可用。

不要贴 API key、OAuth token、私有仓库名或敏感截图。

## 免责声明

这是社区诊断工具，不是 OpenAI 官方项目。

工具会尽量保持保守，但修改本地 Codex 插件状态仍然有风险。执行修复前请阅读输出的 repair plan。
