#!/system/bin/sh

# External Tools
log_handler() {
  if [ "$(id -u)" == 0 ] ; then
	  echo "" >> $INSTLOG
	  echo -e "$(date +"%Y-%m-%d %H:%M:%S:%N") - $1" >> $INSTLOG 2>&1
  fi
}

log_start() {
if [ -f "$INSTLOG" ]; then
  truncate -s 0 $INSTLOG
else
  touch $INSTLOG
fi
  echo " " >> $INSTLOG 2>&1
  echo "    *********************************************" >> $INSTLOG 2>&1
  echo "    *              $MODTITLE                    *" >> $INSTLOG 2>&1
  echo "    *********************************************" >> $INSTLOG 2>&1
  echo "    *                   $VER                    *" >> $INSTLOG 2>&1
  echo "    *********************************************" >> $INSTLOG 2>&1
  echo "    *                $AUTHOR                    *" >> $INSTLOG 2>&1
  echo "    *********************************************" >> $INSTLOG 2>&1
  echo " " >> $INSTLOG 2>&1
  log_handler "Log start."
}

log_print() {
  ui_print "$1"
  log_handler "$1"
}

log_script_chk() {
	log_handler "$1"
	echo -e "$(date +"%m-%d-%Y %H:%M:%S") - $1" >> $INSTLOG 2>&1
}

# Finding file values
get_file_value() {
	if [ -f "$1" ]; then
		grep $2 $1 | sed "s|.*${2}||" | sed 's|\"||g'
	fi
}

collect_logs() {
	log_handler "Collecting logs and information."
	# Create temporary directory
	mkdir -pv $TMPLOGLOC >> $INSTLOG 2>&1

	# Saving Magisk and module log files and device original build.prop
	for ITEM in $LOGGERS; do
		if [ -f "$ITEM" ]; then
			case "$ITEM" in
				*build.prop*)	BPNAME="build_$(echo $ITEM | sed 's|\/build.prop||' | sed 's|.*\/||g').prop"
				;;
				*)	BPNAME=""
				;;
			esac
			cp -af $ITEM ${TMPLOGLOC}/${BPNAME} >> $INSTLOG 2>&1
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
						cp -af $ITEMTPM $TMPLOGLOC >> $INSTLOG 2>&1
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
if $MAGISK; then
  log_handler "RESETPROPS"
  echo "==========================================" >> $INSTLOG 2>&1
	resetprop >> $INSTLOG 2>&1
	log_print " Collecting Modules Installed "
  echo "==========================================" >> $INSTLOG 2>&1
	if [ -d $MODULEROOT ]; then
  	ls $MODULEROOT >> $INSTLOG 2>&1
	fi
	ls $MOUNTEDROOT
  log_print " Collecting Logs for Installed Files "
  echo "==========================================" >> $INSTLOG 2>&1
  log_handler "$(du -ah $MODPATH)" >> $INSTLOG 2>&1
  grep -r "$MODID" -B 1 $MODPATH >> $INSTLOG 2>&1
else
  log_handler "GETPROPS"
  echo "==========================================" >> $INSTLOG 2>&1
	getprop >> $INSTLOG 2>&1
fi

# Package the files                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
cd $CACHELOC || exit
tar -zcvf $MODID_logs.tar.xz $MODID_logs >> $INSTLOG 2>&1

# Copy package to internal storage
mv -f $CACHELOC/$MODID_logs.tar.xz $SDCARD >> $INSTLOG 2>&1

if  [ -e $SDCARD/$MODID_logs.tar.xz ]; then
  log_print "$MODID_logs.tar.xz Created Successfully."
else
  log_print "Archive File Not Created. Error in Script. Please contact the Unity Team"
fi

# Remove temporary directory
rm -rf $TMPLOGLOC >> $INSTLOG 2>&1

log_handler "Logs and information collected."
}

if $BOOTMODE; then
  SDCARD=/storage/emulated/0
else
  SDCARD=/data/media/0
fi

if [ -d /cache ]; then CACHELOC=/cache; else CACHELOC=/data/cache; fi

NVBASE=/data/adb
MODDIRNAME=modules_update
MODULEROOT=$NVBASE/$MODDIRNAME
MODID=$(get_file_value $TMPDIR/module.prop "id=" | sed 's|-.*||')
MOUNTEDROOT=$NVBASE/modules
MODPATH=$MODULEROOT/$MODID
VER=$(get_file_value version $TMPDIR/module.prop "version=" | sed 's|-.*||')
AUTHOR=$(get_file_value author $TMPDIR/module.prop "author=" | sed 's|-.*||')
MODTITLE=$(get_file_value $TMPDIR/module.prop "name=" | sed 's|-.*||')
INSTLOG=$MOUNTEDROOT/$MODID/$MODID-install.log
TMPLOG=$MODID_logs.log
TMPLOGLOC=$MODULEROOT/$MODID/$MODID_logs

LOGGERS="
$CACHELOC/magisk.log
$CACHELOC/magisk.log.bak
$MOUNTEDROOT/$MODID/$MODID-install.log
$SDCARD/$MODID-debug.log
/data/adb/magisk_debug.log
"

chmod -R 0755 $TMPDIR/addon/Logging
cp -R $TMPDIR/addon/Logging $UF/tools 2>/dev/null
PATH=$UF/tools/Logging/:$PATH
mkdir -p $MODPATH
cp -af $UF/tools/Logging/main.sh $MODPATH/logging.sh
sed -i "s|\$MODPATH|$MOUNTEDROOT/$MODID|g" $MODPATH/logging.sh
sed -i "s|\$TMPDIR|$MODPATH|g" $MODPATH/logging.sh
sed -i "s|\$INSTLOG|\$LOG|g" $MODPATH/logging.sh
sed -i "147,159d" $MODPATH/logging.sh
chmod 0755 $MODPATH/logging.sh
chown 0.2000 $MODPATH/logging.sh

