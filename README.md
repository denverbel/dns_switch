# DNS SWITCH
DNS Switch allows you to change your dns systemlessly with terminal. Type su then dns_switch in terminal to enter the menu. Select custom DNS to enter the DNS you would like to use. 
Enter dns_switch -h or dns_switch --help
To check if custom dns is working type nslookup <website> into terminal. for example nslookup google.com.
A new feature has been added thanks to @vr25. Now you can use dns_switch updates without having to reboot! Everything is now symlinked to /sbin

## Compatibility
* All Devices 
* All Android Versions
* Selinux enforcing
* All root solutions (requires init.d support if not using magisk or supersu. Try [Init.d Injector](https://forum.xda-developers.com/android/software-hacking/mod-universal-init-d-injector-wip-t3692105))
* Thanks to @veez21 for mod-util @zackptg5 for unity/modifying mod-util for all root support @didgeridoohan for allowing me to use/modify his logging code

-  DNSCRYPT SUPPORT WILL BE ADDED IN NEXT VERSION

## Change Log
###v12 - 2019.08.03
* Fix functions.sh not found error

### v11 - 2019.08.03
* Fix some typos
* Fix no shebang (script will now run) Sorry about that guys

### v10 - 08.02.2019
* Fix logging (remove as unity addon)
* Rebase entire mod on offical temolate
* Make a few ui_prints more clear
* Next update will have more features. This was more of a stability update more than anything

### v8 - 05.27.2019
* Once and for all fix logging errors. (tough bug)
* Now work can begin on other features!

### v7 - 05.27.2019
* Hopefully fix logging.sh errors once and for all

### v6 - 05.26.2019
* Finally all errors fixed

### v5 - 05.21.2019
* Unity v4.2 update
* Start adding ipv6 and dnscrypt support (finished next release)
* Finally fixed logging.sh error
* Logging finally merged as a unity addon. Get logging template from my github if you'd like to use logging addon.

### v4 - 03.28.2019
* Unity v4 update
* Move logging into addon
* Bug fixes

### v3 - 11.02.2018
* Fix service script

### v2 - 11.02.2018
* Added set on boot support
* Added ability to see custom DNS(s)
* Added a help option. run dns_switch -h or --help to see it
* Upcoming features will be dnscrypt support/dns over https support and a few more surprises

### v1 - 10.26.2018
* Inital Release


## Source Code
* Module [GitHub](https://github.com/JohnFawkes/DNSSwitch)
