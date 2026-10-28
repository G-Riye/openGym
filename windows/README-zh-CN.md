# openGym 1.4.3：Windows 与 iPhone 使用说明

这个目录把官方 openGym 1.4.3 作为网页 App（PWA）运行在你的 Windows 电脑上。iPhone 通过同一 Wi-Fi 访问，可以添加到主屏幕。界面默认使用中文，账户使用用户名和密码登录。

## 在电脑上启动

1. 双击项目根目录的 `Start-openGym.cmd`，保持电脑开机并运行 openGym。
2. 记下启动程序显示的“手机设置”地址。首次地址为 `http://192.168.50.47:8080`；电脑换网络或 IP 改变后，以启动程序显示的地址为准。
3. 如果 iPhone 无法打开此地址，在电脑上双击 `Allow-iPhone.cmd`，确认 Windows 的管理员权限提示，然后重试。

`Allow-iPhone.cmd` 为 Caddy 添加防火墙规则：只允许 Windows 专用网络中的本地子网访问 TCP 8080 和 8443。请在你信任的家庭 Wi-Fi 上使用；如果 Windows 把家庭网络标为“公用”，需要先在该网络的属性中将其设为“专用”。

停止服务时，双击项目根目录的 `Stop-openGym.cmd`。下次使用时重新运行 `Start-openGym.cmd`。目前未配置 Windows 开机自动启动，电脑重启后也需运行该启动程序。

## 在 iPhone 上完成一次设置

1. **连接同一个 Wi-Fi。** iPhone 和电脑应位于同一个家庭网络。访客 Wi-Fi 可能禁止设备互相访问。
2. **用 Safari 打开手机设置页。** 输入启动程序显示的 HTTP 地址，例如 `http://192.168.50.47:8080`。
3. **下载描述文件。** 点击“下载 iPhone 安装描述文件”，下载 `openGym-iphone.mobileconfig`。在 iPhone 的 Safari 提示下载配置描述文件时，选择“允许”。它仅包含这台电脑生成的 `openGym Local Root` 公共根证书。安装页可能显示“未签名”，可在详情中核对唯一内容是这张证书。
4. **安装证书描述文件。** 看到“已下载描述文件”的提示后，回到 iPhone“设置”首页，点击“已下载描述文件”，确认名称为 `openGym Local Root`，再点击右上角“安装”。也可到“设置 → 通用 → VPN 与设备管理”查找下载的描述文件。如果 Safari 只是保存了文件，到“文件 → 下载项”中打开 `openGym-iphone.mobileconfig` 后再回设置。这里的安装步骤与下一步的信任开关是两个页面；未安装的下载会在 8 分钟后自动移除。无需删除已有的 Shadowrocket 描述文件。
5. **开启完全信任。** 进入“设置 → 通用 → 关于本机 → 证书信任设置”，开启 `openGym Local Root` 的完全信任。这会让 iPhone 信任这台电脑签发的 HTTPS 证书；仅安装描述文件不会自动开启 SSL/TLS 信任。
6. **创建个人资料。** 返回 Safari 的设置页，点击“打开 openGym”。首次地址为 `https://192.168.50.47:8443`。选择“创建新档案”，页面会直接显示密码注册表单；输入用户名和至少 10 个字符的密码，并妥善保存。电子邮件可留空，应用不会发送密码重置邮件。
7. **添加到主屏幕。** 在 openGym 页面点击 Safari“分享 → 添加到主屏幕 → 添加”。若显示“作为网页 App 打开”，保持开启。以后从这个图标进入即可。

设置页中的 HTTPS 按钮会使用启动程序当前检测到的电脑地址。请从该按钮进入后再添加主屏幕图标。

## 公网访问：Cloudflare Tunnel（2026-10-29 起）

手机不再需要装 Tailscale，也不依赖动态 IPv6 或 DDNS：本机用出站连接把两个域名接到 Cloudflare，
Https 证书由 Cloudflare 自动签发，电脑 IP 怎么变都不影响。

| 用途 | 地址 | 指向本机 |
|---|---|---|
| openGym App / PWA | `https://gym.469510353.xyz` | `127.0.0.1:8081`（带 64 位令牌门） |
| ChatGPT MCP 连接器 | `https://mcp.469510353.xyz` | `127.0.0.1:8787`（token 在路径里） |

- **首次打开 PWA**：浏览器打开 `https://gym.469510353.xyz/?t=<chatgpt\secrets\app-token 的内容>`，
  令牌会写成 cookie 并跳转；然后在 Safari「分享 → 添加到主屏幕」。换到这个新域名后需要重新添加一次，
  并在 openGym「设置 → 通知」重新打开推送（新域名是新的推送订阅）。
- **原生 App**：地址填 `gym.469510353.xyz`（默认 https、443），配对码仍然在浏览器「设置 → 账户 →
  配对手机 App」生成。App 的 `/api/*`、`/exercise-media/*` 已在 app-proxy 里放行（Bearer / 配对码 /
  预检 / health / config），浏览器 UI 仍然需要令牌。
- **ChatGPT**：把自定义连接器 URL 改成 `https://mcp.469510353.xyz/mcp/<chatgpt\secrets\mcp-token 的内容>`。
- **服务器 ORIGIN**：服务端现在以公网域名为准（`windows\public-origin.txt`），`ORIGINS` 额外允许
  家里 `https://192.168.50.47:8443` 继续登录和写入；通行密钥只在域名下可用，局域网 IP 仍用密码。
- **日常命令**（在 `chatgpt` 目录）：
  - 启动/切换：`powershell -ExecutionPolicy Bypass -File scripts\tunnel.ps1 -Mode cloudflare`
  - 状态：`... -Mode status`；停止：`... -Mode stop`
  - 隧道第一次配置：`scripts\setup-cloudflare.ps1`（已在本机执行过，配置在 `store\cloudflare.json` 与
    `store\cloudflared.yml`；`cloudflared` 已登录过 Cloudflare，证书在 `C:\Users\46951\.cloudflared\cert.pem`）。
  - `Start.cmd` 会按 `store\tunnel-mode.txt`（现在是 `cloudflare`）自动拉起隧道。
- 旧的 Tailscale Funnel 已重置；`tailscale funnel status` 显示 `No serve config`。Tailscale 仍可用于别的事情，
  但 openGym 与 MCP 已经不走它。若之后要换域名：改 `store\cloudflare.json`、`windows\public-origin.txt`，
  重跑 `setup-cloudflare.ps1` 和 `tunnel.ps1 -Mode cloudflare`，再改 ChatGPT 的连接器 URL。

## 日常使用与离线记录

现在的主要入口是上面的公网域名（手机 4G/5G 直接可用）。家里也仍可走局域网 `https://192.168.50.47:8443`；
Tailscale 不再是必需项（此前通过 `AC86U-Home` 发布的 `192.168.50.0/24` 子网路由仍然有效，仅作备用）。

- 电脑开机、openGym 运行，且 iPhone 能通过家庭 Wi-Fi 或 Tailscale 子网路由连接到电脑时，可以访问服务器并同步训练数据。外出时家庭路由器的 Tailscale 也须保持在线。
- 首次请在电脑可连接时打开并使用 openGym，让页面和所需内容缓存下来。之后可以记录离线训练，连接恢复后再同步；首次没有缓存的页面或动作媒体可能仍需网络。
- 电脑关机、休眠或服务停止后，已缓存的内容可能继续可用，但无法立即与电脑同步。恢复连接后，先打开应用确认同步成功，再退出账户或清理浏览器数据。
- 已在家庭路由器为网卡 `FC:34:97:9E:C8:42` 保留 `192.168.50.47`，续租后已核实生效。若以后更换网络导致电脑 IP 改变，重新运行启动程序，并在 iPhone 使用新地址。不同地址会有各自的浏览器缓存和主屏幕入口；迁移前先确认旧地址的数据已同步或已导出备份。

## 备份与账户恢复

在 openGym“设置 → 数据与备份”中定期导出备份，尤其在换手机、更换地址、清理 Safari 数据之前。涉及自定义照片或视频时，选择包含媒体的备份选项。

服务器数据保存在**项目根目录的 `data` 文件夹**。需要备份整个服务器时，先运行 `Stop-openGym.cmd`，将 `data` 复制到你自己的安全备份位置，再重新启动。该文件夹包含账户和服务器密钥，请勿上传到公开仓库或公开分享。

注册不会自动生成恢复码。请保存用户名和密码；忘记密码时，需要管理员为该账户签发一次性重置码，再在“使用密码登录”中的重置入口使用。可选电子邮件只作为登录名，不会收到恢复邮件。

本机 HTTPS 的证书私钥也应保留在电脑本地。手机只需要安装设置页提供的 `openGym-iphone.mobileconfig`，其中包含与 `openGym-root.cer` 相同的公共证书，不含任何 `.key` 文件。

## 常见问题

**手机设置页打不开**

确认电脑已运行 `Start-openGym.cmd`、没有休眠，iPhone 与电脑在同一网络。运行 `Allow-iPhone.cmd` 后重试。若仍失败，检查是否连接访客 Wi-Fi，或路由器是否开启设备隔离。

**HTTPS 页面显示证书不受信任**

确认已安装名称为 `openGym Local Root` 的描述文件，并在“关于本机 → 证书信任设置”中单独开启完全信任。然后使用当前设置页的“打开 openGym”按钮重试。

**界面提示使用通行密钥**

IP 地址不能作为通行密钥所需的有效域名。这套局域网部署已经修正为：在 IPv4 / IPv6 地址下自动使用密码入口，首次选择“创建新档案”即可填写密码；已有账户选择“用密码登录”。如果浏览器仍显示旧页面的“通行密钥 / 密码”选项，先选右侧“密码”，或刷新网页重新打开。域名下的通行密钥能力保留。

**也想在 Windows 浏览器里使用**

电脑上的 HTTP 设置页可以直接查看。若要在 Windows 打开 HTTPS 应用，也需要手动信任本机证书：下载 `http://192.168.50.47:8080/openGym-root.cer`（地址以当前电脑 IP 为准），双击，选择“安装证书 → 当前用户 → 将所有的证书都放入下列存储 → 受信任的根证书颁发机构”，完成后重新打开 HTTPS 地址。启动程序不会自动改动 Windows 的证书信任库。

**更换手机或重新安装了主屏幕图标**

先按上述步骤安装并信任本机证书，再打开当前 HTTPS 地址，使用原用户名和密码登录。服务器上的已同步数据仍保存在项目的 `data` 中。

## 休息结束时在 iPhone 后台或锁屏收到通知

两条路，服务器端都已验证可用：

**A. 继续用主屏幕 PWA（Web Push）**

- 前提：iOS 16.4 或更高；必须用 `https://192.168.50.47:8443` 添加到主屏幕；在 openGym「设置 → 通知」里打开推送；iOS「设置 → 通知 → openGym」允许通知，并关闭「静音投递」。
- 机制：休息开始时手机把结束时间交给服务器，到点由服务器发 Web Push；App 退到后台或被系统挂起也能收到。
- 电脑需要保持开机并运行 openGym，因为推送由这台电脑发出。

**B. 官方 iPhone App（1.4.2 起上架 App Store，推荐）**

- App Store 搜索「openGym: Workout Tracker」，或打开 https://apps.apple.com/app/id6822275400 （免费，中国区可下载，iOS 15.5 及以上）。
- 首次打开选择「连接到我的服务器」，在电脑浏览器打开 `https://192.168.50.47:8443`，进入「设置 → 账户 → 配对手机 App」取一次性配对码（5 分钟有效），在手机里输入服务器地址和配对码。
- 休息提醒用 iOS 本地通知：后台、锁屏都会响，并支持灵动岛和 Apple Watch；不依赖电脑发推送。

纯网页在 iOS 后台定时响铃做不到（后台网页 JS 会被挂起），所以只能选 A 或 B。

## 版本与回滚（2026-10-28 升级，2026-10-29 公网入口）

- 当前版本：官方 upstream **v1.4.3**（2026-10-26）。本地补丁与部署脚本在 fork：`https://github.com/G-Riye/openGym`，分支 `local/1.4.3-gr.1`，标签 `v1.4.3-gr.1`、`v1.4.3-gr.2`、**`v1.4.3-gr.3`**（多 Origin + Cloudflare 公网入口）。
- 2026-10-29 的本地改动只有两处：`api/server.js` 支持 `ORIGINS`（额外允许的写入 Origin，默认是局域网地址；主 `ORIGIN` 改为公网域名，供 WebAuthn 使用），以及 `windows/Start-openGym.ps1` 读取 `windows/public-origin.txt`。
- 升级前备份：`api-1.4.1.bak/`、`frontend/dist-1.4.1.bak/`，以及完整备份目录 `N:\DeepSeek Harness Workspace\backups\openGym-1.4.1-20261028-2023`。
- 回滚：先停止 openGym，把两个 `.bak` 换回 `api/` 和 `frontend/dist/`，再重新启动；公网入口可先 `scripts\tunnel.ps1 -Mode stop`。

## 官方资料

- [openGym 1.4.3 正式发布](https://github.com/DuarteSantos8/openGym/releases/tag/v1.4.3)
- [官方 iPhone / 移动端说明](https://github.com/DuarteSantos8/openGym/blob/v1.4.3/docs/MOBILE.md)
- [官方密码登录说明](https://github.com/DuarteSantos8/openGym/blob/v1.4.3/docs/SELF_HOSTING.md#password-sign-in-optional)
- [Apple：信任手动安装的证书](https://support.apple.com/zh-cn/102390)
- [Apple：安装配置描述文件](https://support.apple.com/zh-cn/102400)
