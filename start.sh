#!/bin/bash

# 获取所有网络接口列表
interfaces=$(ip -o link show | awk -F': ' '{print $2}')

# 初始化一个数组
interfaces_to_include=()

# 遍历所有接口，筛选物理网卡以及 wg0 和 lo 接口
for interface in $interfaces; do
    # 检查是否为物理网卡（不包含虚拟、回环等），并排除@符号及其后面的内容
    if [[ $interface =~ ^(en|eth|vmb).* || $interface == "wg0" || $interface == "lo" ]]; then
        # 去掉@符号及其后面的内容
        interface_name=$(echo "$interface" | awk -F'@' '{print $1}')
        # 将物理网卡、wg0、lo 接口名称添加到数组中
        interfaces_to_include+=("$interface_name")
    fi
done

# 输出物理网卡、wg0 和 lo 接口数组
echo "网卡列表：${interfaces_to_include[@]}"

# 创建并写入 nftables 配置文件
echo "" > "/etc/nftables.conf"
cat <<EOF > "/etc/nftables.conf"
#!/usr/sbin/nft -f
flush ruleset
table inet singbox {
  set local_ipv4 {
    type ipv4_addr
    flags interval
    elements = {
      10.0.0.0/8,
      127.0.0.0/8,
      169.254.0.0/16,
      172.16.0.0/12,
      192.168.0.0/16,
      240.0.0.0/4
    }
  }

  set local_ipv6 {
    type ipv6_addr
    flags interval
    elements = {
      ::ffff:0.0.0.0/96,
      64:ff9b::/96,
      100::/64,
      2001::/32,
      2001:10::/28,
      2001:20::/28,
      2001:db8::/32,
      2002::/16,
      fc00::/7,
      fe80::/10
    }
  }

  chain singbox-tproxy {
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta l4proto { tcp, udp } meta mark set 1 tproxy to :7896 accept
  }

  chain singbox-mark {
    ip daddr @local_ipv4 return
    ip6 daddr @local_ipv6 return
    udp dport { 123 } return
    meta mark set 1
  }

  chain mangle-output {
    type route hook output priority mangle; policy accept;
    meta l4proto { tcp, udp } skgid != 1 ct direction original goto singbox-mark
  }

  chain mangle-prerouting {
    type filter hook prerouting priority mangle; policy accept;
    # 在这里插入逗号分隔的接口列表
    iifname { $(IFS=,; echo "${interfaces_to_include[*]}") } meta l4proto { tcp, udp } ct direction original goto singbox-tproxy
  }
}
EOF

# 提示 nftables 配置写入完成
echo "nftables规则写入完成"

# 清空现有的 nftables 规则
echo "清空 nftables 规则"
nft flush ruleset
sleep 1

# 应用新的 nftables 配置
echo "新规则生效"
sleep 1
/usr/sbin/nft -f /etc/nftables.conf

exec supervisord -c /etc/supervisord.conf