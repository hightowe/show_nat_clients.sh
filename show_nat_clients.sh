#!/bin/bash
# NOTE: Needs to be /bin/ash on OpenWRT w/busybox

##############################################################
# Shows the active NAT clients on a Linux router.
#
# Originally written on a GL.iNet GL-A1300 OpenWRT router.
# Ported to also operate on Ubuntu with isc-dhcp-server.
# First written in September of 2024 by Lester Hightower.
##############################################################

# NOTES:
#
#  GL.iNet's spin of OpenWRT
#  =========================
#  - /tmp/dhcp.leases holds DHCP leases
#  - "ubus call luci-rpc getDHCPLeases" prints leases as JSON
#  - /etc/config/gl-client - Holds "static" client names that are assigned in the GUI
#
#  Ubuntu
#  =========================
#  - /var/lib/dhcp/dhcpd.leases holds DHCP leases for isc-dhcp-server
#    - dhcp-lease-list command for isc-dhcp-server
#    - the leases file only holds entries for unknown (non-static) clients
#    - dhcp-lease-list can be enhanced by placing https://standards-oui.ieee.org/oui/oui.txt
#  - /var/lib/NetworkManager/*.lease holds DHCP leases for NetworkManager

# Configuration variables
DNS_SERVER="localhost"
GL_CLIENTS="/etc/config/gl-client"

# Get the OS ID because we need to do things differently on OpenWRT
OS_ID=$( grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[A-Z]' '[a-z]' )

# We use this because dhcp-lease-list is slow
TEMP_LEASE_LIST="/tmp/dhcp_leases.$$.tmp"
trap 'rm -f "$TEMP_LEASE_LIST"; exit' INT TERM EXIT # 3. Guaranteed cleanup even if Ctrl+C'd or script crashes

# Collect the IPs that this host is NATting for...
natted_IPs=$( conntrack -L  --src-nat --status ASSURED --output extended 2>/dev/null | sed -E -e 's/^[^=]+ src=//' -e 's/ .+$//' | sort -u )

echo -e "IP Address\tMAC Address\t\tDNS Name"
echo -e "----------\t-----------\t\t--------"
for ip in $natted_IPs; do
  # Parse out the MAC address and determine if it is a random one.
  # https://www.mist.com/get-to-know-mac-address-randomization-in-2020/
  mac=$( cat /proc/net/arp | grep "$ip" | awk '{print $4}' | tr '[a-z]' '[A-Z]' )
  # If the MAC isn't in the arp table it might be one of mine...
  if [ -z "$mac" ]; then
    mac=$( ifconfig |grep -A1 "inet $ip" | grep ether | awk '{print $2}' | tr '[a-z]' '[A-Z]' )
  fi
  mac_rand_char=$( echo "$mac" | cut -b2-2 | tr 'a-z' 'A-Z' )
  rand_match=$( expr "$mac_rand_char" : "[26AE]" )
  mac_rand=" " # Not randomized
  [ $rand_match -gt 0 ] && mac_rand="*" # Randomized

  # Try to find the associated name, first via DNS
  NSL_TIMEOUT="-timeout=1"
  [ "$OS_ID" = "openwrt" ] && NSL_TIMEOUT=""  # No -timeout flag on openwrt
  name=$( nslookup $NSL_TIMEOUT "$ip" "$DNS_SERVER" 2>/dev/null | grep 'name = ' | sed -E -e 's/^[^\s]+name = //' -e 's/[.]$//' )
  if [ "$name" = "" ]; then
    #name=$( grep -i -A1 "$mac" "$GL_CLIENTS" | tail -1 )
    if [ -f "$GL_CLIENTS" ] && [ -n "$mac" ]; then
      name=$( awk "BEGIN{IGNORECASE=1}; /$mac/ {do_print=1} do_print==1 {print} NF==0 {do_print=0}" \
	"$GL_CLIENTS" | grep 'option alias' | sed -E -e "s/[^']+'//" -e "s/'//g" )
    fi
    # If there was no GL_CLIENTS file, try ubus (OpenWRT) or dhcp-lease-list (Ubuntu)
    if [ "$name" = "" ]; then
      if command -v ubus >/dev/null 2>&1 && command -v jsonfilter >/dev/null 2>&1; then
        name=$( ubus call luci-rpc getDHCPLeases | jsonfilter -e "@.dhcp_leases[@.macaddr='$mac'].hostname" )
      fi
      if command -v dhcp-lease-list >/dev/null 2>&1; then
        [ -f "$TEMP_LEASE_LIST" ] || dhcp-lease-list --last --parsable 2>/dev/null 1>"$TEMP_LEASE_LIST"
        name=$( cat "$TEMP_LEASE_LIST" | grep -i "$mac" | awk '{print $6}' )
        manuf=$( cat "$TEMP_LEASE_LIST" | grep -i "$mac" | sed -E 's/^.+MANUFACTURER //' )
      fi
    fi
    [ ! "$name" = "" ] && name="$name **" # If we found a name here, denote it with **
    [ ! "$manuf" = "" ] && name="$name ($manuf)"
  fi
  echo -e "$ip\t$mac$mac_rand\t$name"
done

