@echo off
setlocal

rem Define the output file path
set "outputFile=%~dp0network_packup_info.txt"
rem Clear the output file if it exists and add initial content
> "%outputFile%" echo====Firewall_Rule====
>> "%outputFile%" echo rule name=Kill_Switch_Any_VPN
>> "%outputFile%" echo.
>> "%outputFile%" echo =====Network Name, Network Category=====
>> "%outputFile%" echo.
rem Use PowerShell to get network profiles and their categories
powershell -Command "Get-NetConnectionProfile | ForEach-Object { \"$($_.Name), $($_.NetworkCategory)\" }" >> "%outputFile%"
>> "%outputFile%" echo.
rem Output firewall profiles
>> "%outputFile%" echo -----windows defender firewall with advanced security on local computer properties----------------------------:
>> "%outputFile%" echo =====domainprofile=====:
powershell netsh advfirewall show domainprofile >> "%outputFile%"
>> "%outputFile%" echo =====privateprofile====:
powershell netsh advfirewall show privateprofile >> "%outputFile%"
>> "%outputFile%" echo ======publicprofile=====:
powershell netsh advfirewall show publicprofile >> "%outputFile%"
>> "%outputFile%" echo.
>> "%outputFile%" echo =====Microsoft Teredo Tunneling Adapter Status=====:
rem Output Teredo Tunneling Adapter Status
netsh interface teredo show state >> "%outputFile%"

echo Network information has been saved to %outputFile%
endlocal
pause
