# 保留原 IP 的 openGym 外网访问方案

目标网址：`https://192.168.50.47:8443`，在家和外出时保持相同。

## 使用路由器已有的子网路由

已核实家庭路由器 `AC86U-Home` 在线，且 `192.168.50.0/24` 已是有效子网路由，覆盖 openGym 的目标 IP。手机连接同一 Tailscale 网络后，可以经这台路由器访问家庭网段，无需电脑额外发布 `/32` 路由。

此前新增的电脑 `192.168.50.47/32` 路由已撤销；电脑的 Shields Up 已恢复原来的开启状态。Windows 未选择出口节点，默认网关仍是家庭路由器 `192.168.50.1`。

## 两种独立功能

- `192.168.50.0/24` 子网路由：让外出的手机访问家里的 `192.168.50.x` 设备。
- 路由器的“Use as exit node”：允许客户端将互联网流量通过家里出口转发。后台批准后，还需要在客户端单独选择它；只访问 openGym 时，手机的 Exit Node 可以选择 None。

用户确认：通过手机热点进入后台，关闭路由器的 Exit Node 后，电脑重新连接宽带，Clash 恢复正常。当前保留路由器的 `/24` 子网路由，Exit Node 保持关闭。精确故障机制尚未确认，不重新开启该项作为 openGym 的必要步骤。

## 固定地址和启动状态

2026-10-16，用户确认已在路由器为网卡 MAC `FC:34:97:9E:C8:42` 保留 `192.168.50.47`。执行 DHCP 续租后，已核实电脑重新取得 `.47`，并成功启动 openGym。原网址的 HTTPS 证书验证、应用资源、API、PWA 和手机尺寸浏览器检查均通过；Clash 代理访问微软返回 HTTP 200。

目前未配置 Windows 开机自动启动。电脑重启后，运行项目根目录的 `Start-openGym.cmd`。电脑须保持开机、openGym 运行，路由器的 Tailscale 也需在线。

2026-10-16，用户确认 iPhone 关闭 Wi-Fi、使用蜂窝网络并连接 Tailscale，Exit Node 选择“无 / None”后，可以在 Safari 通过原网址正常打开并登录。外网访问和登录已由用户实测确认。

## Clash 排查记录

Windows 系统代理指向 `127.0.0.1:7897`，由 `verge-mihomo` 监听。检查时，Mihomo 运行在规则模式、TUN 关闭。本机对百度和微软的直接请求，以及明确通过该代理端口的请求，均得到 HTTP 200。用户确认关闭路由器 Exit Node 后已恢复宽带下的 Clash 访问；这些结果仍不足以将此前故障归因于单独的 `/32` 路由。

## 官方资料

- [Tailscale 子网路由说明](https://tailscale.com/docs/features/subnet-routers)
- [Tailscale Exit Node 说明](https://tailscale.com/docs/features/exit-nodes)
- [路由选择规则](https://tailscale.com/docs/reference/route-injection)
