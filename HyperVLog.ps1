<#

.DESCRIPTION
   Aktivieren des mitloggen der CPU und Ram Auslastung der Virtuellen Maschinen eines lokalen Hyper-V Hosts
.EXAMPLE
   HyperVLog 
   Startet das logging mit Standardspreicherort C:\VM.csv
.EXAMPLE
   HyperVLog -Stop
   Beendet einen laufenden Logging Task
.EXAMPLE
   HyperVLog -Intervall 5
   Startet einen LoggingTask mit einem Intervall von 5 Minuten
.INPUTS
   -Intervall  //in Minuten
   -Start
   -Stop
.OUTPUTS
   Ausgabe dieses Cmdlets (falls vorhanden)
.NOTES
   Allgemeine Hinweise
.COMPONENT
   Die Komponente, zu der dieses Cmdlet gehört
.ROLE
   Die Rolle, zu der dieses Cmdlet gehört
.FUNCTIONALITY
   Die Funktionalität, die dieses Cmdlet am besten beschreibt
#>


[CmdletBinding()]
Param(
    [Parameter()]
    [int]$Intervall = 5,

    [Parameter()]
    [switch]$Start = $true,

    [Parameter()]
    [switch]$Stop = $false

)



cls
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID);
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator;
if ($myWindowsPrincipal.IsInRole($adminRole)) 
    {    
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)";  
    }
    else
    {
    $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"    
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess) | Out-Null;
    Exit;
    }
if((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell).State.ToString() -eq "Enabled" -and (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State.ToString() -eq "Enabled")
{

cls
    Write-Host "Hyper-V Rolle und PowerShellModul ist installiert" -ForegroundColor Green
    if ($Start -eq $true -and $Stop -eq $false)
    {
        $exshudeled = Get-ScheduledJob
        foreach ($shed in $exshudeled)
        {
            if($shed.Name -eq "HyperVLog")
            {
                
                Write-Host -ForegroundColor Yellow "Es ist schon ein Task angelegt mit dem Namen: " -NoNewline
                Write-Host -ForegroundColor Cyan $shed.Name 
                Write-Host -ForegroundColor Yellow "Zum beenden des Loggings HyperVLog.ps1 -Stop ausführen"
                Read-Host "..........Zum beenden beliebige Taste drücken............." 
                exit 2
            }
        }
    
        $sc = {
            $allVM = Get-VM 
            foreach($VM in $allVM)
            {   
                $Datensatz = "" | Select-Object Zeitstempel, VmName, Status, CPU, Ram
                $Datensatz.Zeitstempel = Get-Date
                $Datensatz.VmName = $VM.Name.ToString()
                $Datensatz.Status = $VM.State
                $Datensatz.CPU = $VM.CPUUsage
                $Datensatz.Ram = $VM.MemoryDemand
                try
                {
                    $Datensatz | Export-Csv -Path C:\VM.csv -Append -Delimiter ";" -Force -ErrorVariable $ExpError
                }
                catch
                {
                    Write-Host $ExpError -ForegroundColor Red 
                    Unregister-ScheduledJob -Name HyperVLog
                    $ExpError | Out-File -FilePath C:\HyperVLog.txt -Append 
                }                
                
            }
        }
        $joboption = New-ScheduledJobOption -RunElevated -HideInTaskScheduler
        $Timespan = New-TimeSpan -Minutes 5
        [DateTime]$atdate = (Get-Date).AddMinutes(5)
        $trigger = New-JobTrigger -Once -At $atdate -RepetitionInterval $Timespan -RepeatIndefinitely
        Register-ScheduledJob -Name "HyperVLog" -Trigger $trigger -ScheduledJobOption $joboption -ScriptBlock $sc  
    }
    elseif($Start -eq $false -and $Stop -eq $true)
    {
        Unregister-ScheduledJob -Name HyperVLog
    }
    else
    {
        Write-Host -ForegroundColor Yellow "Entweder -Start oder -Stop verwenden "
    }

}
else
{
    Write-Host -ForegroundColor Red "Hyper-V ist auf dem System nicht existent"
}       

    




