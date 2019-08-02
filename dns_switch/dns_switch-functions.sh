invaild() {
echo -e "${R}Invaild Option...${N}"; clear
}

return_menu() {
  echo -n "${R}Return to menu? < y | n > : ${N}"
  read -r mchoice
  case $mchoice in
    y|Y) menu;;
    n|N) clear; quit;;
    *) invaild;;
  esac
}

# DNSLoggers
DNSLOGGERS="
$CACHELOC/magisk.log
$CACHELOC/magisk.log.bak
$MODPATH/${MODID}-install.log
$MODPATH/${MODID}.log
$MODPATH/${MODID}-old.log
$SDCARD/${MODID}-debug.log
/data/adb/magisk_debug.log
$MODPATH/${MODID}-verbose-old.log
$MODPATH/${MODID}-verbose.log
"

log_handler() {
	if [ $(id -u) == 0 ] ; then
		echo "" >> $DNSLOG 2>&1
		echo -e "$(date +"%m-%d-%Y %H:%M:%S") - $1" >> $DNSLOG 2>&1
	fi
}

log_print() {
	echo "$1"
	log_handler "$1"
}

log_script_chk() {
log_handler "$1"
	echo -e "$(date +"%m-%d-%Y %H:%M:%S") - $1" >> $DNSLOG 2>&1
}

get_file_value() {
	cat $1 | grep $2 | sed "s|.*$2||" | sed 's|\"||g'
}

#DNSLog Functions
# Saves the previous DNSlog (if available) and creates a new one
log_start() {
if [ -f "$DNSLOG" ]; then
	mv -f $DNSLOG $oldDNSLOG
fi
touch $DNSLOG
echo " " >> $DNSLOG 2>&1
echo "    *********************************************" >> $DNSLOG 2>&1
echo "    *               $MODTITLE                   *" >> $DNSLOG 2>&1
echo "    *********************************************" >> $DNSLOG 2>&1
echo "    *                 $VER                      *" >> $DNSLOG 2>&1
echo "    *********************************************" >> $DNSLOG 2>&1
echo "    *              John Fawkes                  *" >> $DNSLOG 2>&1
echo "    *********************************************" >> $DNSLOG 2>&1
echo " " >> $DNSLOG 2>&1 
log_script_chk "Log start."
}

# PRINT MOD NAME
collect_logs() {
log_handler "Collecting logs and information."
	# Create temporary directory
	mkdir -pv $TMPDNSLOGLOC >> $DNSLOG 2>&1

	# Saving Magisk and module DNSlog files and device original build.prop
	for ITEM in $DNSLOGGERS; do
		if [ -f "$ITEM" ]; then
			case "$ITEM" in
				*build.prop*)	BPNAME="build_$(echo $ITEM | sed 's|\/build.prop||' | sed 's|.*\/||g').prop"
				;;
				*)	BPNAME=""
				;;
			esac
			cp -af $ITEM ${TMPDNSLOGLOC}/${BPNAME} >> $DNSLOG 2>&1
		else
			case "$ITEM" in
				*/cache)
					if [ "$CACHELOC" == "/cache" ]; then
						CACHELOCTMP=/cache
					else
						CACHELOCTMP=/data/cache
					fi
					ITEMTPM=$(echo $ITEM | sed 's|$CACHELOC|$CACHELOCTMP|')
					if [ -f "$ITEMTPM" ]; then
						cp -af $ITEMTPM $TMPDNSLOGLOC >> $DNSLOG 2>&1
					else
						log_handler "$ITEM not available."				
          fi
        ;;
				*)	log_handler "$ITEM not available."
        ;;
			esac
    fi
	done

# Saving the current prop values
  log_handler "RESETPROPS"
  echo "==========================================" >> $DNSLOG 2>&1
	resetprop >> $DNSLOG 2>&1
  log_print " Collecting Modules Installed "
  echo "==========================================" >> $DNSLOG 2>&1
  ls /data/adb/modules >> $DNSLOG 2>&1
  log_print " Collecting Logs for Installed Files "
  echo "==========================================" >> $DNSLOG 2>&1
  log_handler "$(du -ah $MODPATH)" >> $DNSLOG 2>&1
  echo "==========================================" >> $DNSLOG 2>&1

# Package the files
cd $CACHELOC
tar -zcvf dns_switch_logs.tar.xz dns_switch_logs >> $DNSLOG 2>&1

# Copy package to internal storage
mv -f $CACHELOC/dns_switch_logs.tar.xz $SDCARD >> $DNSLOG 2>&1

if  [ -e $SDCARD/dns_switch_logs.tar.xz ]; then
  log_print "dns_switch_logs.tar.xz Created Successfully."
else
  log_print "Archive File Not Created. Error in Script. Please contact JohnFawks"
fi

# Remove temporary directory
rm -rf $TMPDNSLOGLOC >> $DNSLOG 2>&1
log_handler "Logs and information collected."
}

# Load functions
log_start "Running Log script." >> $DNSLOG 2>&

# Find prop type
get_prop_type() {
	echo $1 | sed 's|.*\.||'
}

# Get left side of =
get_eq_left() {
	echo $1 | sed 's|=.*||'
}

# Get right side of =
get_eq_right() {
	echo $1 | sed 's|.*=||'
}

# Get first word in string
get_first() {
	case $1 in
		*\ *) echo $1 | sed 's|\ .*||'
		;;
		*=*) get_eq_left "$1"
		;;
	esac
}

help_me() {
  cat << EOF
$MODTITLE $VER($REL)
by $AUTHOR

Usage: $_name
   or: $_name [options]...
   
Options:
    -nc                    removes ANSI escape codes
    -r                     remove DNS
    -c [DNS ADRESS]        add custom DNS
    -l                     list custom DNS server(s) in use
    -h                     show this message
EOF
exit
}

get_crypt () {

curl -s https://api.github.com/repos/jedisct1/dnscrypt-proxy/releases/latest | grep browser_download_url | grep android_$ARCH | cut -d : -f 2,3 | tr -d \" | wget -qi -

}

dnscrypt_menu (){
echo "NOT READY"
echo "NEXT RELEASE"
sleep 2
menu
}

DNSlog_menu () DNSlogresponse=""
choice=""

  echo "$div"
  echo "" 
  echo "${G}***DNSLOGGING MAIN MENU***${N}"
  echo ""
  echo "$div"
  echo ""
  echo "${G}Do You Want To Take DNSLogs?${N}"
  echo ""
  echo -n "${Y}Enter (y)es or (n)o${N}"
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"
  read -r DNSlogresponse
case $DNSlogresponse in
  y|Y|yes|Yes|YES)
  upload_DNSlogs
  ;;
  *)
  return_menu
  ;;
esac
}

dns_remove () {

custom=$(echo $(get_file_value $DNSDNSLOG "custom=") | sed 's|-.*||')
custom2=$(echo $(get_file_value $DNSDNSLOG "custom2=") | sed 's|-.*||')

resetprop --delete net.eth0.dns1
resetprop --delete net.eth0.dns2
resetprop --delete net.dns1
resetprop --delete net.dns2
resetprop --delete net.ppp0.dns1
resetprop --delete net.ppp0.dns2
resetprop --delete net.rmnet0.dns1
resetprop --delete net.rmnet0.dns2
resetprop --delete net.rmnet1.dns1
resetprop --delete net.rmnet1.dns2
resetprop --delete net.pdpbr1.dns1
resetprop --delete net.pdpbr1.dns2

if [ -f $MODPATH/system/etc/resolv.conf ]; then
  sed -i "/nameserver\ "$custom"/d" $MODPATH/system/etc/resolv.conf
  if [ "$custom2" ]; then
    sed -i "/nameserver\ "$custom2"/d" $MODPATH/system/etc/resolv.conf
  fi
fi
return_menu
}

re_dns_menu () {

response=""
choice=""

  echo "$div"
  echo ""
  echo "${G}***REMOVE CUSTOM DNS MENU***${N}"
  echo ""
  echo "$div"
  echo ""
  echo -n "${G}Do You Want to Remove Your Custom DNS?${N}" 
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"
  read -r response
case $respone in
  y|Y|yes|Yes|YES)
  dns_remove
  ;;
  *)
  return_menu
  ;;
esac
}

dns_menu () {

custom=""
custom2=""
choice=""

  echo "$div"
  echo ""
  echo "${G}***CUSTOM DNS MENU***${N}"
  echo ""
  echo "$div"
  echo ""
  echo -n "${G}Please Enter Your Custom DNS${N}" 
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"
  echo ""
  read -r custom
if [ -n $custom ]; then
  touch $DNSDNSLOG
  set_perm $DNSDNSLOG 0 0 0644
  truncate -s 0 $DNSDNSLOG
  truncate -s 0 $DNSSERV
  echo "custom=$custom" >> $DNSDNSLOG 2>&1
  setprop net.eth0.dns1 $custom
  setprop net.dns1 $custom
  setprop net.ppp0.dns1 $custom
  setprop net.rmnet0.dns1 $custom
  setprop net.rmnet1.dns1 $custom
  setprop net.pdpbr1.dns1 $custom
  echo "iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination $custom:53" >> $DNSSERV 2>&1
  echo "iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to-destination $custom:53" >> $DNSSERV 2>&1
fi
echo ""
echo -n "${G} Would You Like to Enter a Second DNS?${N}"
echo ""
echo -n "${y} Enter (y)es or (n)o${N}"
echo ""
echo -n "${R} [CHOOSE] :   ${N}"
echo ""
read -r choice
echo ""
case $choice in
  y|Y|yes|Yes|YES)
  echo -n "${G} Please Enter Your Custom DNS2${N}"
  echo ""
  echo -n "${R} [CHOOSE]  :  ${N}"
  echo ""
  read -r custom2
  if [ -n $custom2 ]; then
    echo "custom2=$custom2" >> $DNSDNSLOG 2>&1
    setprop net.eth0.dns2 $custom2
    setprop net.dns2 $custom2
    setprop net.ppp0.dns2 $custom2
    setprop net.rmnet0.dns2 $custom2
    setprop net.rmnet1.dns2 $custom2
    setprop net.pdpbr1.dns2 $custom2
    echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination $custom2:53" >> $DNSSERV 2>&1 
    echo "iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to-destination $custom2:53" >> $DNSSERV 2>&1
  fi
  if [ -f /system/etc/resolv.conf ]; then
    mkdir -p $MODPATH/system/etc
    cp -f /system/etc/resolv.conf $MODPATH/system/etc
    printf "nameserver $custom\nnameserver $custom2" >> $MODPATH/system/etc/resolv.conf
    set_perm $MODPATH/system/etc/resolv.conf 0 0 0644
  fi
  ;;
  *)
  invaild
  ;;
esac
return_menu
} 