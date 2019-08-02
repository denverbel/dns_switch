
# Terminal Magisk Mod Template
# by veez21 @ xda-developers
# Modified by @JohnFawkes - Telegram
# Supersu/all-root compatibility with Unity and @Zackptg5
# Variables

OLDPATH=$PATH
MODID=dns_switch
MODPATH=/data/adb/modules/$MODID
MODPROP=$MODPATH/module.prop
if [ -d /cache ]; then CACHELOC=/cache; else CACHELOC=/data/cache; fi
SDCARD=/storage/emulated/0
TMPLOG=DNSSwitch_logs.log
TMPLOGLOC=$CACHELOC/DNSSwitch_logs
DNSLOG=$MODPATH/${MODID}.log
oldDNSLOG=$MODPATH/${MODID}-old.log
DNSSERV=$MODPATH/service.sh
alias curl=$MODPATH/curl
alias sleep=$MODPATH/sleep

quit() {
  PATH=$OLDPATH
  exit $?
}

# Detect root
_name=$(basename $0)
ls /data >/dev/null 2>&1 || { echo "$MODID needs to run as root!"; echo "type 'su' then '$_name'"; quit 1; }

# Load magisk stuff
if [ -f /data/adb/magisk/util_functions.sh ]; then
  . /data/adb/magisk/util_functions.sh
elif [ -f /data/magisk/util_functions.sh ]; then
  . /data/magisk/util_functions.sh
else
  echo "! Can't find magisk util_functions! Aborting!"; exit 1
fi

# Load Needed Functions
if [ -f $MODPATH/${MODID}-functions ]; then
  . $MODPATH/${MODID}-functions
else
  echo "! Can't find functions script! Aborting!"; exit 1
fi

log_start
#=========================== Set Log Files
#mount -o remount,rw $CACHELOC 2>/dev/null
#mount -o rw,remount $CACHELOC 2>/dev/null
# > Logs should go in this file
#LOG=$MODPATH/$MODID.log
#oldLOG=$MODPATH/$MODID-old.log
# > Verbose output goes here
VERLOG=$MODPATH/${MODID}-verbose.log
oldVERLOG=$MODPATH/${MODID}-verbose-old.log

# Start Logging verbosely
mv -f $VERLOG $oldVERLOG 2>/dev/null
set -x 2>$VERLOG

# Set Busybox up
if [ "$(busybox 2>/dev/null)" ]; then
  BBox=true
elif [ -d /sbin/.core/busybox ]; then
  PATH=/sbin/.core/busybox:$PATH
 _bb=/sbin/.core/busybox/busybox
  BBox=true
elif [ -d /sbin/.magisk/busybox ]; then
  PATH=/sbin/.magisk/busybox:$PATH
  _bb=/sbin/.magisk/busybox/busybox
  BBox=true
elif [ -d /data/adb/magisk/busybox ]; then
  PATH=/data/adb/magisk/busybox:PATH
  _bb=/data/adb/magisk/busybox
  BBox=true
elif [ -d /data/magisk/busybox ]; then
  PATH=/data/magisk/busybox:PATH
  _bb=/data/magisk/busybox
  BBox=true
else
  BBox=false
  echo "! Busybox not detected" >> $DNSLOG
  echo "Please install one (@osm0sis' busybox recommended)" >> $DNSLOG
  for applet in cat chmod cp curl grep md5sum mv ping printf sed sleep sort tar tee tr unzip wget; do
    [ "$($applet)" ] || quit 1
  done
  echo "All required applets present, continuing" >> $DNSLOG
fi

if [ -z "$(echo $PATH | grep /sbin:)" ]; then
 alias resetprop="/data/adb/magisk/magisk resetprop"
fi

# Log print
echo "Functions loaded." >> $DNSLOG
if $BBox; then
  BBV=$(busybox | grep "BusyBox v" | sed 's|.*BusyBox ||' | sed 's| (.*||')
  echo "Using busybox: ${PATH} (${BBV})." >> $DNSLOG
else
  echo "Using installed applets (not busybox)" >> $DNSLOG
fi

# Functions
get_file_value() {
  if [ -f "$1" ]; then
    grep $2 $1 | sed "s|.*${2}||" | sed 's|\"||g'
  fi
} 

api_level_arch_detect() {
  API=$(grep_prop ro.build.version.sdk)
  ABI=$(grep_prop ro.product.cpu.abi | cut -c-3)
  ABI2=$(grep_prop ro.product.cpu.abi2 | cut -c-3)
  ABILONG=$(grep_prop ro.product.cpu.abi)
  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  [ -z $5 ] && chcon 'u:object_r:system_file:s0' $1 || chcon $5 $1 || return 1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

# Mktouch
mktouch() {
  mkdir -p ${1%/*} 2>/dev/null
  [ -z $2 ] && touch $1 || echo $2 > $1
  chmod 644 $1
}

# Grep prop
grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

# Abort
abort() {
  echo "$1"
  exit 1
}

magisk_version() {
if grep MAGISK_VER /data/adb/magisk/util_functions.sh; then
  echo "$MAGISK_VERSION $MAGISK_VERSIONCODE" >> $DNSLOG 2>&1
else
  echo "Magisk not installed" >> $DNSLOG 2>&1
fi
}

# Device Info
# BRAND MODEL DEVICE API ABI ABI2 ABILONG ARCH
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ROM=$(getprop ro.build.display.id)
api_level_arch_detect
# Version Number
VER=$(echo $(get_file_value $MODPROP "version=") | sed 's|-.*||')
# Version Code
REL=$(echo $(get_file_value $MODPROP "versionCode=") | sed 's|-.*||')
# Author
AUTHOR=$(echo $(get_file_value $MODPROP "author=") | sed 's|-.*||')
# Mod Name/Title
MODTITLE=$(echo $(get_file_value $MODPROP "name=") | sed 's|-.*||')
#Grab Magisk Version
MAGISK_VERSION=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VER=") | sed 's|-.*||')
MAGISK_VERSIONCODE=$(echo $(get_file_value /data/adb/magisk/util_functions.sh "MAGISK_VER_CODE=") | sed 's|-.*||')

# Colors
G='\e[01;32m'  # GREEN TEXT
R='\e[01;31m'  # RED TEXT
Y='\e[01;33m'  # YELLOW TEXT
B='\e[01;34m'  # BLUE TEXT
V='\e[01;35m'  # VIOLET TEXT
Bl='\e[01;30m'  # BLACK TEXT
C='\e[01;36m'  # CYAN TEXT
W='\e[01;37m'  # WHITE TEXT
BGBL='\e[1;30;47m' # Background W Text Bl
N='\e[0m'   # How to use (example): echo "${G}example${N}"
loadBar=' '   # Load UI
# Remove color codes if -nc or in ADB Shell
[ -n "$1" -a "$1" == "-nc" ] && shift && NC=true
[ "$NC" -o -n "$LOGNAME" ] && {
  G=''; R=''; Y=''; B=''; V=''; Bl=''; C=''; W=''; N=''; BGBL=''; loadBar='=';
}

# No. of characters in $MODTITLE, $VER, and $REL
character_no=$(echo "$MODTITLE $VER $REL" | wc -c)

# Divider
div="${Bl}$(printf '%*s' "${character_no}" '' | tr " " "=")${N}"

# title_div [-c] <title>
# based on $div with <title>
title_div() {
  [ "$1" == "-c" ] && local character_no=$2 && shift 2
  [ -z "$1" ] && { local message=; no=0; } || { local message="$@ "; local no=$(echo "$@" | wc -c); }
  [ $character_no -gt $no ] && local extdiv=$((character_no-no)) || { echo "Invalid!"; return; }
  echo "${W}$message${N}${Bl}$(printf '%*s' "$extdiv" '' | tr " " "=")${N}"
}

# set_file_prop <property> <value> <prop.file>
set_file_prop() {
if [ -f "$3" ]; then
  if grep -q "$1=" "$3"; then
    sed -i "s/${1}=.*/${1}=${2}/g" "$3"
  else
    echo "$1=$2" >> "$3"
  fi
else
  echo "$3 doesn't exist!"
fi
}

# https://github.com/fearside/ProgressBar
# ProgressBar <progress> <total>
ProgressBar() {
# Determine Screen Size
  if [[ "$COLUMNS" -le "57" ]]; then
    local var1=2
	  local var2=20
  else
    local var1=4
    local var2=40
  fi
# Process data
  local _progress=$(((${1}*100/${2}*100)/100))
  local _done=$(((${_progress}*${var1})/10))
  local _left=$((${var2}-$_done))
# Build progressbar string lengths
  local _done=$(printf "%${_done}s")
  local _left=$(printf "%${_left}s")

# Build progressbar strings and print the ProgressBar line
printf "\rProgress : ${BGBL}|${N}${_done// /${BGBL}$loadBar${N}}${_left// / }${BGBL}|${N} ${_progress}%%"
}

#https://github.com/fearside/SimpleProgressSpinner
# Spinner <message>
Spinner() {

# Choose which character to show.
case ${_indicator} in
  "|") _indicator="/";;
  "/") _indicator="-";;
  "-") _indicator="\\";;
  "\\") _indicator="|";;
  # Initiate spinner character
  *) _indicator="\\";;
esac

# Print simple progress spinner
printf "\r${@} [${_indicator}]"
}

# cmd & spinner <message>
e_spinner() {
  PID=$!
  h=0; anim='-\|/';
  while [ -d /proc/$PID ]; do
    h=$(((h+1)%4))
    sleep 0.02
    printf "\r${@} [${anim:$h:1}]"
  done
}                                                                       

# test_connection
# tests if there's internet connection
test_connection() {
  ui_print " [-] Testing internet connection [-] "
  ping -q -c 1 -W 1 google.com >/dev/null 2>&1 && ui_print " [-] Internet Detected [-] "  && CON=true || { abort " [-] Error, No Internet Connection [-] ";NCON=true; }
}

test_connection2() {
  case "$(curl -s --max-time 2 -I http://google.com | sed 's/^[^ ]*  *\([0-9]\).*/\1/; 1q')" in
  [23]) ui_print " [-] HTTP connectivity is up [-] "
    CON2=true
    ;;
  5) ui_print " [!] The web proxy won't let us through [!] "
    NCON2=true
    ;;
  *) ui_print " [!] The network is down or very slow [!] "
    NCON2=true
    ;;
esac
}

test_connection3() {
  wget -q --tries=5 --timeout=10 http://www.google.com -O $MODPATH/google.idx >/dev/null 2>&1
if [ ! -s $MODPATH/google.idx ]
then
    ui_print " [!] Not Connected... [!] "
    NCON3=true
else
    ui_print " [-] Connected..! [-] "
    CON3=true
fi
rm -f $MODPATH/google.idx
}

# Log files will be uploaded to termbin.com
# Logs included: VERLOG LOG oldVERLOG oldLOG
upload_logs() {
  $BBok && {
    test_connection3
    [ $CON3 ] || test_connection2
    [ $CON2 ] || test_connection
    if [ $CON ] || [ $CON2 ] || [ $CON3 ]; then
      echo "Uploading logs"
      [ -s $VERLOG ] && verUp=$(cat $VERLOG | nc termbin.com 9999) || verUp=none
      [ -s $oldVERLOG ] && oldverUp=$(cat $oldVERLOG | nc termbin.com 9999) || oldverUp=none
      [ -s $DNSLOG ] && logUp=$(cat $DNSLOG | nc termbin.com 9999) || logUp=none
      [ -s $oldDNSLOG ] && oldlogUp=$(cat $oldDNSLOG | nc termbin.com 9999) || oldlogUp=none
      echo -n "Link: "
      echo "$MODEL ($DEVICE) API $API\n$ROM\n$ID\n
      O_Verbose: $oldverUp
      Verbose:   $verUp
      O_Log: $oldlogUp
      Log:   $logUp" | nc termbin.com 9999
    fi
  } || echo "Busybox not found!"
  exit
}

# Print Center
# Prints text in the center of terminal
pcenter() {
  local CHAR=$(printf "$@" | sed 's|\\e[[0-9;]*m||g' | wc -m)
  local hfCOLUMN=$((COLUMNS/2))
  local hfCHAR=$((CHAR/2))
  local indent=$((hfCOLUMN-hfCHAR))
  echo "$(printf '%*s' "${indent}" '') $@"
}

reboot(){
  setprop sys.powerctl reboot
}

# Heading
mod_head() {
  echo "$div"
  echo "${W}$MODTITLE $VER${N}(${Bl}$REL${N})"
  echo "by ${W}$AUTHOR${N}"
  echo "$div"
  echo "${R}$BRAND${N},${R}$MODEL${N},${R}$ROM${N}"
  echo "$div"
  echo "${W}BUSYBOX VERSION = ${N}${R}$_bbname${N}${R}$BBV${N}"
  echo "$div"
  echo "${W}MAGISK VERSION = ${N}${R} $MAGISK_VERSION${N}" 
  echo "$div"
  echo ""
}

#=========================== Main
# > You can start your MOD here.
# > You can add functions, variables & etc.
# > Rather than editing the default vars above.

menu () {
  
choice=""
custom=$(echo $(get_file_value $DNSLOG "custom=") | sed 's|-.*||')
custom2=$(echo $(get_file_value $DNSLOG "custom2=") | sed 's|-.*||')

while [ "$choice" != "q" ]
  do  	
  mod_head
  echo "$div"
  echo "${G}***DNS MAIN MENU***${N}"
  echo "$div"
  echo ""
  echo "$div"
  if [ "$custom" ]; then
    echo -e "${W}Your Custom DNS is :${N} ${R}$custom${N}"
  fi
  if [ "$custom2" ]; then
    echo -e "${W}Your Second Custom DNS is :${N} ${R}$custom2${N}"
  fi
  echo "$div"
  echo "${G}Please make a Selection${N}"
  echo ""
  echo -e "${W}1)${N} ${B}Enter Custom DNS${N}"
  echo ""
  echo -e "${W}2)${N} ${B}Remove Custom DNS${N}"
  echo ""
  echo -e "${W}3)${N} ${B}DNSCrypt${N}"
  echo ""
  echo -e "${W}Q)${N} ${B}Quit${N}"
  echo ""
  echo -e "${W}L)${N} ${B}Logs${N}"
  echo "$div"
  echo ""
  echo -n "${R}[CHOOSE] :  ${N}"

  read -r choice
 
  case $choice in
  1) echo "${G} Custom DNS Menu Selected... ${N}"
  sleep 1
  clear
  dns_menu
  ;;
  2) echo "${B} Remove Custom DNS Selected... ${N}"
  sleep 1
  clear
  re_dns_menu
  ;;
  3) echo "${B} DNSCrypt Selected... ${N}"
  sleep 1
  clear
  dnscrypt_menu
  ;;
  q|Q) echo " ${R}Quiting... ${N}"
  sleep 1
  clear
  quitcp -f $TMPDIR/${MODID}-functions.sh $MODPATH/${MODID}-functions.sh
  ;;
  l|L) echo "${R}Logs Selected...${N}"
  sleep 1
  clear
  log_menu
  ;;
  *) echo "${Y}item not available! Try Again${N}"
  sleep 1.5
  clear
  ;;
  esac
done
}

case $1 in
-c|-C) shift
  dns_menu;;
-r|-R) shift
  dns_remove
  exit;;
-l|-L) shift
custom=$(echo $(get_file_value $DNSLOG "custom=") | sed 's|-.*||')
custom2=$(echo $(get_file_value $DNSLOG "custom2=") | sed 's|-.*||')
  if [ "$custom" ]; then
    echo -e "${W}Your Custom DNS is :${N} ${R}$custom${N}"
  elif [ "$custom2" ]; then
    echo -e "${W}Your Second Custom DNS is :${N} ${R}$custom2${N}"
  else
    echo -e "${R}NO CUSTOM DNS IN USE${N}"
    echo -e "${R}Please run 'su' then 'dns_switch' to use a custom DNS${N}"
  fi
  exit;;
-h|--help) help_me;;
esac  

menu

quit $?
