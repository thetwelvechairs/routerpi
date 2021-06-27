sudo bash -c '
# usb / eth1 / wan MAC ADDRESS
ETH1="eth1"
# eth0 / lan MAC ADDRESS
ETH0="eth0"

ROUTER_IP="10.0.1.1"

echo "SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\""${ETH1}"\", NAME=\"wan\"
SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\""${ETH0}"\", NAME=\"lan\"
" > /etc/udev/rules.d/10-network.rules

echo "auto wan
allow-hotplug wan
iface wan inet dhcp" > /etc/network/interfaces.d/wan

echo "allow-hotplug lan
iface lan inet static
        address "${ROUTER_IP}"
        netmask 255.255.255.0
        gateway "${ROUTER_IP}"" > /etc/network/interfaces.d/lan

sudo systemctl disable dhcpcd
sudo apt-get install isc-dhcp-server -y

sed -i "s/INTERFACESv4=\".*/INTERFACESv4=\"lan\"/" /etc/default/isc-dhcp-server
sed -i "s/option domain-name .*/option domain-name \"router.local\";/" /etc/dhcp/dhcpd.conf
sed -i "s/option domain-name-servers .*/option domain-name-servers 10.0.1.2, 8.8.8.8, 1.1.1.1;/" /etc/dhcp/dhcpd.conf

echo "authoritative;
subnet 10.0.1.0 netmask 255.255.255.0 {
        range 10.0.1.10 10.0.1.100;
        option routers "${ROUTER_IP}";
        option subnet-mask 255.255.255.0;
}" >> /etc/dhcp/dhcpd.conf

echo "host router {
        hardware ethernet "${ETH0}";
        fixed-address "${ROUTER_IP}";
}" >> /etc/dhcp/dhcpd.conf

sudo systemctl restart isc-dhcp-server -y

sudo firewall-cmd --zone=home --add-interface=lan
sudo firewall-cmd --zone=public --add-interface=ppp0
sudo firewall-cmd --zone=public --add-interface=wan
sudo firewall-cmd --zone=public --add-masquerade
sudo firewall-cmd --zone=home --add-service=dns
sudo firewall-cmd --zone=home --add-service=dhcp

sudo firewall-cmd --runtime-to-permanent

sudo iptables -A INPUT -i eth1 -p tcp --dport 22 -j DROP
'
