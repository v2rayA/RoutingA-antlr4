# RoutingA

## 基础规则

```bash
# 自定义入站 inbound，支持http, socks
inbound:httpauthin=http(address: 0.0.0.0, port: 1081, user: user1, pass: user1pass, user:user2, pass:user2pass)
inbound:socksauthin=socks(address: 0.0.0.0, port: 1082, user: 123, pass: 123)
inbound:sockslocalin=socks(address: 127.0.0.1, port: 1080)
inbound:sniffing_socks=socks(address: 127.0.0.1, port: 1080, sniffing: http, sniffing: tls)
inbound:sniffing_http=http(address: 127.0.0.1, port: 1081, sniffing: 'http, tls')

# 自定义出站 outbound，支持http, socks, freedom
outbound:httpout=http(address: 127.0.0.1, port: 8080, user: 'my-username', pass: 'my-password')
outbound:socksout=socks(address: 127.0.0.1, port: 10800, user: "my-username", pass: "my-password")
outbound:special=freedom(domainStrategy: AsIs, redirect: "127.0.0.1:3366", userLevel: 0)

# 设置默认outbound，不设置则默认为proxy （该选项只作用于默认入站）
default: httpout

# 预设三个outbounds: proxy, block, direct

# 域名规则
domain(domain: v2raya.org) -> socksout
domain(full: dns.google) -> proxy
domain(contains: facebook) -> proxy
domain(regexp: \.goo.*\.com$) -> proxy
domain(geosite:category-ads) -> block
domain(geosite:cn)->direct

# 目的IP规则
ip(8.8.8.8) -> direct
ip(101.97.0.0/16) -> direct
ip(geoip:private) -> direct

# 源IP规则
source(192.168.0.0/24) -> proxy
source(192.168.50.0/24) -> direct

# 目的端口规则
port(80) -> direct
port(10080-30000) -> direct

# 源端口规则
sourcePort(38563) -> direct
sourcePort(10080-30000) -> direct

# 多域名规则
domain(contains: google, domain: www.twitter.com, domain: v2raya.org) -> proxy
# 多IP规则
ip(geoip:cn, geoip:private) -> direct
ip(9.9.9.9, 223.5.5.5) -> direct
source(192.168.0.6, 192.168.0.10, 192.168.0.15) -> direct

# inbound 入站规则
inboundTag(httpauthin, socksauthin) -> direct
inboundTag(sockslocalin) -> special

# 同时满足规则
ip(geoip:cn) && port(80) && user(mzz2017@tuta.io) -> direct
ip(8.8.8.8) && network(tcp, udp) && port(1-1023, 8443) -> proxy
ip(1.1.1.1) && protocol(http) && source(10.0.0.1, 172.20.0.0/16) -> direct
```

## 扩展规则

**多规则共用 outbound**

```bash
{
    ip(geoip:cn, geoip:private)
    ip(9.9.9.9, 223.5.5.5)
    source(192.168.0.6, 192.168.0.10, 192.168.0.15)
} -> direct
```

它等同于如下规则：

```bash
ip(geoip:cn, geoip:private) -> direct
ip(9.9.9.9, 223.5.5.5) -> direct
source(192.168.0.6, 192.168.0.10, 192.168.0.15) -> direct
```

**多规则共用前置规则**

```bash
inboundTag(socks5_auth) && port(443) && {
    domain(geosite:geolocation-!cn)
    domain(geosite:google-scholar)
} -> proxy

inboundTag(socks5_auth) && port(443) && {
    domain(geosite:geolocation-!cn) -> direct
    domain(geosite:google-scholar) -> proxy
}
```

它等同于如下规则：

```bash
inboundTag(socks5_auth) && port(443) && domain(geosite:geolocation-!cn) -> proxy
inboundTag(socks5_auth) && port(443) && domain(geosite:google-scholar) -> proxy

inboundTag(socks5_auth) && port(443) && domain(geosite:geolocation-!cn) -> direct
inboundTag(socks5_auth) && port(443) && domain(geosite:google-scholar) -> proxy
```

复杂地：

```bash
inboundTag(socks5_auth) && port(443) && {
	protocol(udp) && port(53) && {
		ip(223.5.5.5)
		ip(8.8.8.8)
		domain(domain: dns.pub)
	}
    domain(geosite:geolocation-!cn)
    domain(geosite:google-scholar)
} -> proxy
```

它等同于如下规则：

```bash
inboundTag(socks5_auth) && port(443) && protocol(udp) && port(53) && ip(223.5.5.5) -> proxy
inboundTag(socks5_auth) && port(443) && protocol(udp) && port(53) && ip(8.8.8.8) -> proxy
inboundTag(socks5_auth) && port(443) && protocol(udp) && port(53) && domain(domain: dns.pub) -> proxy
inboundTag(socks5_auth) && port(443) && domain(geosite:geolocation-!cn) -> proxy
inboundTag(socks5_auth) && port(443) && domain(geosite:google-scholar) -> proxy
```



**条件生效规则**

```bash
condition: scene1

# 当 condition 的值为 scene1 时，块内的规则生效
@condition==scene1 {
	default: proxy
	{
        ip(geoip:cn, geoip:private)
        ip(9.9.9.9, 223.5.5.5)
        source(192.168.0.6, 192.168.0.10, 192.168.0.15)
    } -> direct
}
# 当 condition 的值为 scene2 时，块内的规则生效
@condition==scene2 {
    default: direct
    domain(geosite:google-scholar)->proxy
    domain(geosite:category-scholar-!cn, geosite:category-scholar-cn)->direct
    domain(geosite:geolocation-!cn)->proxy
    	ip("91.105.192.0/23","91.108.4.0/22","91.108.8.0/21","91.108.16.0/21","91.108.56.0/22","95.161.64.0/20","149.154.160.0/20","185.76.151.0/24","2001:67c:4e8::/48","2001:b28:f23c::/47","2001:b28:f23f::/48","2a0a:f280:203::/48")->proxy
}

@condition==scene3 default: block
@condition==scene3 domain(baidu.com)->direct
```

**注释**

```c++
condition: scene1

# 单行注释，只有该行被跳过

/* 多行注释，块内规则均被跳过

# 当 condition 的值为 scene1 时，块内的规则生效
@condition==scene1 {
	default: proxy
	{
        ip(geoip:cn, geoip:private)
        ip(9.9.9.9, 223.5.5.5)
        source(192.168.0.6, 192.168.0.10, 192.168.0.15)
    } -> direct
}
# 当 condition 的值为 scene2 时，块内的规则生效
@condition==scene2 {
    default: direct
    domain(geosite:google-scholar)->proxy
    domain(geosite:category-scholar-!cn, geosite:category-scholar-cn)->direct
    domain(geosite:geolocation-!cn)->proxy
    	ip("91.105.192.0/23","91.108.4.0/22","91.108.8.0/21","91.108.16.0/21","91.108.56.0/22","95.161.64.0/20","149.154.160.0/20","185.76.151.0/24","2001:67c:4e8::/48","2001:b28:f23c::/47","2001:b28:f23f::/48","2a0a:f280:203::/48")->proxy
}

*/
@condition==scene3 default: block
@condition==scene3 domain(baidu.com)->direct
```

