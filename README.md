# NetRouteProxy

一个简易的端口中转程序，支持 TCP 和 UDP 端口转发，带可视化 WEB 管理界面。

## 一键安装

使用如下命令一键安装并注册为系统服务（无需 screen、支持 systemctl 命令管理，服务名为 `nr`）：

```bash
curl -s https://raw.githubusercontent.com/Azizi030/NetRouteProxy/main/install_netrouteproxy.sh | sudo bash
```

## 系统服务管理命令

安装完成后，NetRouteProxy 会作为 systemd 服务自动运行。你可以使用如下命令管理：

```bash
systemctl start nr      # 启动服务
systemctl stop nr       # 停止服务
systemctl restart nr    # 重启服务
systemctl status nr     # 查看服务状态
```

## Web 管理面板

安装成功后，Web 管理面板会在所有网卡的 8088 端口监听。可通过如下地址访问（公网/内网 IP 均可）：

```bash
# 查看所有可访问地址
for ip in $(hostname -I); do echo "http://$ip:8088"; done
```

## 主要功能

- TCP/UDP 端口转发
- Web 可视化管理规则
- 热加载，无需重启即可生效
- 一键安装，systemctl 命令管理，无需 screen

## 规则配置示例（proxy_rules.json）

```json
{
  "61697": {"remote_ip": "192.168.5.20", "remote_port": "8080", "remark": "TCP示例", "protocol": "tcp"},
  "60000": {"remote_ip": "192.168.5.20", "remote_port": "8080", "remark": "UDP示例", "protocol": "udp"}
}
```

## 常见问题

- **为什么公网无法访问管理面板？**  
  请检查防火墙安全组是否放行 8088 端口。

- **如何卸载？**  
  停止并禁用服务，然后删除程序目录和 systemd 单元文件：

  ```bash
  systemctl stop nr
  systemctl disable nr
  rm -rf /opt/netrouteproxy
  rm /etc/systemd/system/nr.service
  systemctl daemon-reload
  ```

---

© 2025 鱼丸工作室