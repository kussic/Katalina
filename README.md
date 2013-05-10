Katalina
========

Katalina is an automation tool for launching KARMA wireless assessments. It's an implementation of Karmetasploit that works via Airbase-NG.

It's designed with BackTrack/Kali in mind but should work an any Linux operating system with the right prerequisites.

What does it do:

* Creates the right dhcpd.conf file if it doesn’t exit
* It creates the right karma.rc file for Metasploit to use
* Lists and enables monitor mode on the wireless interface of choice
* Kicks off Airbase-NG
* Allows to specify a rogue AP SSID (by default it emulates a FON)
* Verbose mode tails /var/log/messages in its own window allowing you to see any connections
* It can reinitialise the wireless driver if it didn’t work (some drivers require this under VMs) 