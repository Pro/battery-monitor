#Battery Monitor Script 0.2
# based on http://www.rivnet.ro/2010/05/log-battery-and-power-levels-using-powershell.html


#-------------------------------
# You can modify the following settings to fit your needs

# Check interval to detect power changes
$checkInterval = 1
# Log interval in seconds when on battery power.
$batteryLogInterval = 300
# Log interval in seconds when on AC power.
$acLogInterval = 3600

#-------------------------------



#create custom event-log if it doesn't exist already
$condition = ((get-wmiobject -class "Win32_NTEventlogFile" | where {$_.LogFileName -like 'BatteryMonitor'} | measure-object ).count -eq '0')
if($condition) {
	'create event log'
    New-EventLog -Source BattMon -LogName BatteryMonitor 
}

#signal script execution start    
Write-EventLog -LogName BatteryMonitor -Source BattMon -EventID 65533 -Message 'Starting new Execution of BatteryCharge Monitor Script' -EntryType Information -ComputerName $env:computername -ErrorAction:SilentlyContinue

$prevBatteryStatus = 2
$prevLogTime = 0


do {
#clear any previous values
    $PowstatMsg = $null
    $ChargeRemMsg = $null
    $RemTimeMsg = $null
	
#create a Message object that we can add values to    
    $Message = ''
    $Message =  $Message | select-object *,PowStatMsg,ChargeRemMsg,RemTimeMsg
   
        
    $batt = Get-WmiObject -Class Win32_Battery
#1 means on battery, 2 on ac power
    If ($batt.BatteryStatus -like '1') {
        $Message.PowstatMsg = 'On_Battery'
        'PowerStatus: On_Battery' }
    elseif ($batt.BatteryStatus -like '2') {
        $Message.PowstatMsg = 'AC_Power'
        'PowerStatus: AC_Power' }
	
        
#If charge is larger than 100, it means it is full/on ac power
    if ($batt.EstimatedChargeRemaining -lt '100') {
        'EstimatedChargeRemaining: ' + $batt.EstimatedChargeRemaining + '%'
        $Message.ChargeRemMsg = "{0:P0}" -f ($batt.EstimatedChargeRemaining/100) }
     else {
        'EstimatedChargeRemaining: 100%'
        $Message.ChargeRemMsg = "{0:P0}" -f 1 }

#If estimated minutes is an absurdly high value, it means we are on AC power
    if ($batt.EstimatedRUntime -lt '9999') {
        'EstimatedRunTime: ' + $batt.EstimatedRunTime + 'min' 
        $Message.RemTimeMsg = $batt.EstimatedRunTime }
     else {
        $Message.RemTimeMsg = 'N/A' }

	If ($batt.BatteryStatus -ne $prevBatteryStatus) {
		if ($prevBatteryStatus -like '2') {
			$EventMsg = "Switched to Battery Power! $($Message.ChargeRemMsg), Minutes: $($Message.RemTimeMsg)"
		} else {
			$EventMsg = "Switched back to AC Power! $($Message.ChargeRemMsg), Minutes: $($Message.RemTimeMsg)"
		}
		Write-EventLog -LogName BatteryMonitor -Source BattMon -EventID 65534 -Message $EventMsg -EntryType Warning -ComputerName $env:computername -ErrorAction:SilentlyContinue
		$prevLogTime = New-TimeSpan "01 January 1970 00:00:00" $(Get-Date)
	}
	$prevBatteryStatus = $batt.BatteryStatus
	
	$currLogTime = New-TimeSpan "01 January 1970 00:00:00" $(Get-Date)
	$diff = $currLogTime.TotalSeconds - $prevLogTime.TotalSeconds
	
	if ($prevBatteryStatus -like '2') {
		#AC Power
		if ($diff -ge $acLogInterval) {
		   $EventMsg = "$($Message.PowStatMsg), $($Message.ChargeRemMsg), $($Message.RemTimeMsg)"
			Write-EventLog -LogName BatteryMonitor -Source BattMon -EventID 65534 -Message $EventMsg -EntryType Information -ComputerName $env:computername -ErrorAction:SilentlyContinue
			$prevLogTime = New-TimeSpan "01 January 1970 00:00:00" $(Get-Date)
		}
	} elseif ($prevBatteryStatus -like '1') {
		# Battery power
		if ($diff -ge $batteryLogInterval) {
		   $EventMsg = "$($Message.PowStatMsg), $($Message.ChargeRemMsg), $($Message.RemTimeMsg)"
			Write-EventLog -LogName BatteryMonitor -Source BattMon -EventID 65534 -Message $EventMsg -EntryType Information -ComputerName $env:computername -ErrorAction:SilentlyContinue
			$prevLogTime = New-TimeSpan "01 January 1970 00:00:00" $(Get-Date)
		}
	}
    
    Sleep $checkInterval
}
while (1)