#!/usr/bin/bash

IP=${IP:-"172.22.0.1"}
HTTP_PORT=${HTTP_PORT:-"80"}
DHCP_RANGE=${DHCP_RANGE:-"172.22.0.10,172.22.0.100"}
INTERFACE=${INTERFACE:-"provisioning"}
EXCEPT_INTERFACE=${EXCEPT_INTERFACE:-"lo"}

mkdir -p /shared/html
mkdir -p /shared/tftpboot

# Copy files to shared mount
cp /tmp/inspector.ipxe /shared/html/inspector.ipxe
cp /tmp/dualboot.ipxe /shared/html/dualboot.ipxe
cp /usr/share/ipxe/undionly.kpxe /usr/share/ipxe/ipxe.efi /shared/tftpboot

# Use configured values
sed -i -e s/IRONIC_IP/$IP/g -e s/HTTP_PORT/$HTTP_PORT/g \
       -e s/DHCP_RANGE/$DHCP_RANGE/g -e s/INTERFACE/$INTERFACE/g /etc/dnsmasq.conf
sed -i -e s/IRONIC_IP/$IP/g -e s/HTTP_PORT/$HTTP_PORT/g /shared/html/inspector.ipxe 
for iface in $( echo $EXCEPT_INTERFACE | tr ',' ' '); do
    sed -i -e "/^interface=.*/ a\except-interface=$iface" /etc/dnsmasq.conf
done

/usr/sbin/dnsmasq -d -q -C /etc/dnsmasq.conf &
/bin/runhealthcheck "dnsmasq" &>/dev/null &
sleep infinity

