log_start
sed -i "s|<CACHELOC>|$CACHELOC|" $TMPDIR/system/xbin/dns_switch >> $INSTLOG 2>&1
if $MAGISK; then
  sed -i "s|<MODPROP>|$(echo $MOD_VER)|" $TMPDIR/system/xbin/dns_switch >> $INSTLOG 2>&1
else
  sed -i "s|<MODPROP>|$MOD_VER|" $TMPDIR/system/xbin/dns_switch >> $INSTLOG 2>&1
fi
patch_script $TMPDIR/system/xbin/dns_switch >> $INSTLOG 2>&1

cp_ch $TMPDIR/logging.sh $MODPATH
