#!/bin/sh

dhcpConf="interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
"
dnsmasqConf="interface=wlan0      # Use the require wireless interface - usually wlan0
  dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
"
hostapDaemonConf='DAEMON_CONF="/etc/hostapd/hostapd.conf"
DAEMON_OPTS="-dd -t -f /var/log/hostapd.log"
'
hostapConf="interface=wlan0

driver=nl80211
channel=11

macaddr_acl=0

deny_mac_file=/etc/hostapd/hostapd.deny

ieee80211n=1          # 802.11n support
wmm_enabled=1         # QoS support
obss_interval=300
ht_capab=[SHORT-GI-20][DSSS_CCK-40]

beacon_int=50
dtim_period=20

basic_rates=180 240 360 480 540

ssid=SSID
hw_mode=g
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP

ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
"
wvdialConf='[Dialer play]
Modem = /dev/ttyUSB0
Baud = 57600
Init1 = ATH
Init2 = ATE1
Init3 = AT+CGDCONT=1,"IP","internet"
Dial Command = ATD
Phone = *99#
Stupid mode = yes
Username = "blank"
Password = "blank"
'

sudo su
apt-get install hostapd dnsmasq wvdial ppp usb_modeswitch -y
systemctl stop hostapd.service dnsmasq.service
echo "$dhcpConf" >> /etc/dhcpcd.conf
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo "$dnsmasqConf" >> /etc/dnsmasq.conf
echo "$hostapConf" >> /etc/hostapd/hostapd.conf
echo "$hostapDaemonConf" >> /etc/default/hostapd
touch /etc/hostapd/hostapd.deny
sysctl net.ipv4.ip_forward=1
iptables -t nat -A  POSTROUTING -o ppp0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"
echo "$wvdialConf" >> /etc/wvdial.conf
echo "sleep 60; pon.wvdial.play; sleep 30;" >> /etc/rc.local
echo "iptables-restore < /etc/iptables.ipv4.nat" >> /etc/rc.local
systemctl enable hostapd dnsmasq
reboot

