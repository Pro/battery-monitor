battery-monitor
===============

PowerShell script to log current battery status of your PC.

This script can be used on your laptop or Windows Server to log current battery level in the EventLog.
If you use it on Windows Server, the UPS should be recognized as a battery. For APC UPS you have to uninstall and remove all previously installed drivers. This will install the default Windows driver which recognizes the UPS as a Battery.

You can even modify this script to execute special actions on Power change (Battery -> AC -> Battery).

# Installation
Simply download the script and execute it as an Administrator.
This should create the "BatteryMonitor" EventLog under Application- and Serviceprotocols.

To start the script at startup you can put it into Autostart or Taskplanner.