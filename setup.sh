# usb / eth1
PRIMARY_DEVICE_MAC=""
# eth0
SECONDARY_DEVICE_MAC=""

ROUTER_IP="10.0.1.1"

DNS_IP="10.0.1.2"

sudo systemctl disable dhcpcd

sudo apt install isc-dhcp-server firewalld hostapd -y

sudo echo 'SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="'${PRIMARY_DEVICE_MAC}'", NAME="lan"' > /etc/udev/rules.d/10-network.rules

sudo echo 'auto wan
allow-hotplug wan
iface wan inet dhcp' > /etc/network/interfaces.d/wan

sudo echo 'allow-hotplug lan
iface lan inet static
        address '${ROUTER_IP}'
        netmask 255.255.255.0
        gateway '${ROUTER_IP} > /etc/network/interfaces.d/lan

sudo sed -i 's/INTERFACESv4=".*/INTERFACESv4="lan"/' /etc/default/isc-dhcp-server
sudo sed -i 's/option domain-name .*/option domain-name "router.local";/' /etc/dhcp/dhcpd.conf
sudo sed -i 's/option domain-name-servers .*/option domain-name-servers 8.8.8.8, 1.1.1.1;/' /etc/dhcp/dhcpd.conf

sudo echo 'authoritative;
subnet 10.0.1.0 netmask 255.255.255.0 {
        range 10.0.1.10 10.0.1.199;
        option routers '${ROUTER_IP}';
        option subnet-mask 255.255.255.0;
}' >> /etc/dhcp/dhcpd.conf

sudo echo 'host router {
        hardware ethernet '${PRIMARY_DEVICE_MAC}';
        fixed-address '${ROUTER_IP}';
}' >> /etc/dhcp/dhcpd.conf


sudo firewall-cmd --zone=home --add-interface=lan
sudo firewall-cmd --zone=public --add-interface=ppp0
sudo firewall-cmd --zone=public --add-interface=wan
sudo firewall-cmd --zone=public --add-masquerade
sudo firewall-cmd --zone=home --add-service=dns
sudo firewall-cmd --zone=home --add-service=dhcp

sudo firewall-cmd --runtime-to-permanent
