@echo off
:reloadTools
echo Starting up the program and verifying resources...
REM Assign a value to a variable // đặt biến
set ruleMain=Cloudflare WARP Executable
set ruleCli=WARP Command Line Interface Executable
set ruleDex=WARP Diagnostics Extended Executable
set ruleDiag=WARP Diagnostics Executable
set ruleSvc=WARP Service Executable

set "warp-loc=C:\Program Files\Cloudflare\Cloudflare WARP"
set "warp-main=%warp-loc%\Cloudflare WARP.exe"
set "warp-cli=%warp-loc%\warp-cli.exe"
set "warp-dex=%warp-loc%\warp-dex.exe"
set "warp-diag=%warp-loc%\warp-diag.exe"
set "warp-svc=%warp-loc%\warp-svc.exe"

set action=allow
set profile=any

REM Verify if the file is executed with admin rights // kiểm tra tệp có được chạy dưới quyền admin không
net session >nul 2>nul
if not %errorlevel% == 0 (
	cls
    echo You need to run this script as an administrator.
    echo. & echo Press any key to exit...
	pause >nul
    exit /b
)

REM Path testing // kiểm tra đường dẫn
if not exist "%warp-loc%" (
	cls
    echo Default Cloudflare WARP folder: "C:\Program Files\Cloudflare\Cloudflare WARP"
    echo Cloudflare WARP folder not found.
    echo. & echo Press any key to exit...
	pause >nul
    exit
)

REM Main menu // Menu chính
:menu
REM status check // kiểm tra trạng thái
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    set killSwitchStatus=Active
) else (
    set killSwitchStatus=Disabled
)
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Disconnected" >nul
IF %ERRORLEVEL% == 0 (
	set warpStatus=Disconnected
	
) ELSE (
	set warpStatus=Connected
)
cls
REM MENU  // tuỳ chọn
echo Kill Switch (Status: %killSwitchStatus%)
echo        WARP (Status: %warpStatus%)
echo. & echo. Options:
echo    1. Enable
echo    2. Disable
echo    3. Ping Test
echo    4. Reload tools
echo    5. Exit
echo.
REM To give options // đưa ra lựa chọn
choice /c 12345 /n /m "Enter your choice: "
set "choice=%errorlevel%"
cls
REM To execute a choice // thực thi lựa chọn
if "%choice%"=="1" goto on
if "%choice%"=="2" goto off
if "%choice%"=="3" goto preKillSwitchTest
if "%choice%"=="4" goto reloadTools
if "%choice%"=="5" goto exit

:on
cls
echo :/menu/enable/
echo Kill Switch Modes:
echo. & echo  Please select a security mode: &echo.
echo   1. Maximum Security (May cause issues with Zero Trust, WARP updates off)
echo   2. High Security (Zero Trust-compatible)
echo   3. Standard Security (Reliable, protected)
echo   4. Return to main menu
echo.
REM To give options // đưa ra lựa chọn
choice /c 1234 /n /m "Enter your choice: "
set "choiceModel=%errorlevel%"
cls
REM To execute a choice // thực thi lựa chọn
if "%choiceModel%"=="1" goto onMaximum
if "%choiceModel%"=="2" goto onHigh
if "%choiceModel%"=="3" goto onStandard
if "%choiceModel%"=="4" goto menu

:onMaximum
echo :/menu/enable/security_mode/maximum
REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    echo Outbound rule named "%ruleSvc%" has been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleSvc%" dir=out action=%action% program="%warp-svc%" enable=yes profile=%profile% >nul
    echo Outbound Rules name="%ruleSvc%" have been successfully created.
)
REM Set inbound and outbound connections to Block for Private profile. // Đặt kết nối đầu vào và đầu ra thành Chặn cho cấu hình mạng Riêng tư.
netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound >nul
echo Domain profile has been set to block inbound and outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound >nul
echo Private profile has been set to block inbound and outbound connections.
netsh advfirewall set publicprofile firewallpolicy blockinbound,allowoutbound >nul
echo Public profile has been set to block inbound, allow outbound connections.

REM Set the network profile type to Private. // Cài đặt loại cấu hình mạng thành Riêng tư.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Private" >nul
echo Network profile type has been set to Private.
REM exclude CloudflareWARP // loại trừ con CloudflareWARP này ra phải để Public nó mới chay được
powershell -Command "Set-NetConnectionProfile -InterfaceAlias 'CloudflareWARP' -NetworkCategory Public" >nul
echo CloudflareWARP profile type has been set to Public.

echo.
timeout /t 1 /nobreak >nul
warp-cli connect >nul
:warpCheckConnectLoopMaximum
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Connected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 >nul
	goto warpCheckConnectLoopMaximum
) 
echo WARP has connected successfully.
timeout /t 4
goto menu

:onHigh
echo :/menu/enable/security_mode/high
REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    echo Outbound rule named "%ruleSvc%" has been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleSvc%" dir=out action=%action% program="%warp-svc%" enable=yes profile=%profile% >nul
    echo Outbound Rules name="%ruleSvc%" have been successfully created.
)
netsh advfirewall firewall show rule name="%ruleMain%" dir=out | find /I "%ruleMain%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleMain%" have been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleMain%" dir=out action=%action% program="%warp-main%" enable=yes profile=%profile% >nul
    echo Outbound Rules name="%ruleMain%" have been successfully created.
)
REM Set inbound and outbound connections to Block for Private profile. // Đặt kết nối đầu vào và đầu ra thành Chặn cho cấu hình mạng Riêng tư.
netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound >nul
echo Domain profile has been set to block inbound and outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound >nul
echo Private profile has been set to block inbound and outbound connections.
netsh advfirewall set publicprofile firewallpolicy blockinbound,allowoutbound >nul
echo Public profile has been set to block inbound, allow outbound connections.

REM Set the network profile type to Private. // Cài đặt loại cấu hình mạng thành Riêng tư.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Private" >nul
echo Network profile type has been set to Private.
REM exclude CloudflareWARP // loại trừ con CloudflareWARP này ra phải để Public nó mới chay được
powershell -Command "Set-NetConnectionProfile -InterfaceAlias 'CloudflareWARP' -NetworkCategory Public" >nul
echo CloudflareWARP profile type has been set to Public.

echo.
timeout /t 1 /nobreak >nul
warp-cli connect >nul
:warpCheckConnectLoopHigh
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Connected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 >nul
	goto warpCheckConnectLoopHigh
) 
echo WARP has connected successfully.
timeout /t 4
goto menu

:onStandard
echo :/menu/enable/security_mode/standard
REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%ruleMain%" dir=out | find /I "%ruleMain%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleMain%" have been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleMain%" dir=out action=%action% program="%warp-main%" enable=yes profile=%profile% >nul
    echo Outbound Rules name="%ruleMain%" have been successfully created.
)
netsh advfirewall firewall show rule name="%ruleCli%" dir=out | find /I "%ruleCli%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleCli%" have been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleCli%" dir=out action=%action% program="%warp-cli%" enable=yes profile=%profile% >nul
    echo Outbound Rules name="%ruleCli%" have been successfully created.
)
netsh advfirewall firewall show rule name="%ruleDex%" dir=out | find /I "%ruleDex%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleDex%" have been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleDex%" dir=out action=%action% program="%warp-dex%" enable=yes profile=%profile% >nul
    echo Outbound Rules name="%ruleDex%" have been successfully created.
)
netsh advfirewall firewall show rule name="%ruleDiag%" dir=out | find /I "%ruleDiag%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleDiag%" have been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleDiag%" dir=out action=%action% program="%warp-diag%" enable=yes profile=%profile% >nul
    echo Outbound Rules name="%ruleDiag%" have been successfully created.
)
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    echo Outbound rule named "%ruleSvc%" has been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleSvc%" dir=out action=%action% program="%warp-svc%" enable=yes profile=%profile% >nul
    echo Outbound Rules name="%ruleSvc%" have been successfully created. Moving on to the next step.
)
REM Set inbound and outbound connections to Block for Private profile. // Đặt kết nối đầu vào và đầu ra thành Chặn cho cấu hình mạng Riêng tư.
netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound >nul
echo Domain profile has been set to block inbound and outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound >nul
echo Private profile has been set to block inbound and outbound connections.
netsh advfirewall set publicprofile firewallpolicy blockinbound,allowoutbound >nul
echo Public profile has been set to block inbound, allow outbound connections.

REM Set the network profile type to Private. // Cài đặt loại cấu hình mạng thành Riêng tư.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Private" >nul
echo Network profile type has been set to Private.
REM exclude CloudflareWARP // loại trừ con CloudflareWARP này ra phải để Public nó mới chay được
powershell -Command "Set-NetConnectionProfile -InterfaceAlias 'CloudflareWARP' -NetworkCategory Public" >nul
echo CloudflareWARP profile type has been set to Public.

echo.
timeout /t 1 /nobreak >nul
warp-cli connect >nul
:warpCheckConnectLoopStandard
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Connected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 >nul
	goto warpCheckConnectLoopStandard
) 
echo WARP has connected successfully.
timeout /t 4
goto menu

:off
echo :/menu/disable
echo Restoring Windows to factory settings...
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Public" >nul
echo Network profile type has been set to Public.
netsh advfirewall set publicprofile firewallpolicy blockinbound,allowoutbound >nul
echo Public profile has been set to block inbound, allow outbound connections.
netsh advfirewall set domainprofile firewallpolicy blockinbound,allowoutbound >nul
echo The domain profile has been configured to block inbound connections and allow outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,allowoutbound >nul
echo The Private profile has been configured to block inbound connections and allow outbound connections.
netsh advfirewall firewall delete rule name="%ruleMain%" Direction=out >nul
netsh advfirewall firewall delete rule name="%ruleCli%" Direction=out >nul
netsh advfirewall firewall delete rule name="%ruleDex%" Direction=out >nul
netsh advfirewall firewall delete rule name="%ruleDiag%" Direction=out >nul
netsh advfirewall firewall delete rule name="%ruleSvc%" Direction=out >nul
echo The outbound rules has been removed.
warp-cli disconnect >nul
:warpCheckDisconnectLoopOff
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Disconnected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 /nobreak >nul
	goto warpCheckDisconnectLoopOff
)
echo. & echo WARP has Disconnect successfully.
timeout /t 4
goto menu

:preKillSwitchTest
cls
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Disconnected" >nul
IF %ERRORLEVEL% == 0 (
	echo pls turn on kill Switch before test
	timeout /t 4
	goto menu
	
) ELSE (
	if %killSwitchStatus%==Active (
		goto killSwitchTest
	)
)
:killSwitchTest
warp-cli connect >nul
:killSwitchCheck1
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Connected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 >nul
	goto killSwitchCheck1
) 
echo WARP has connected.
echo START CHECKING:
ping 8.8.8.8 | findstr /C:"Reply"
IF %ERRORLEVEL% == 0 (
	echo. & echo  OK!
) else (
	echo. & echo  NOT OK!
)

warp-cli disconnect >nul
:killSwitchCheck2
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Disconnected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 3 /nobreak >nul
	goto killSwitchCheck2
)
echo. & echo WARP has Disconnect.
echo START CHECKING:
ping 8.8.8.8 | findstr /C:"General failure"
IF %ERRORLEVEL% == 0 (
	echo. & echo  OK!
) else (
	echo. & echo  NOT OK!
)
timeout /t 1 >nul
echo. & echo Activating WARP connection again. Please wait... 
warp-cli connect >nul
:warpConnectTurnOnAfterCheck
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Connected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 >nul
	goto warpConnectTurnOnAfterCheck
)
echo WARP connection has been re-enabled.
echo. & echo Check completed.
echo Press any key to return to the menu...
pause >nul
goto menu

:exit
echo EXIT...
exit
