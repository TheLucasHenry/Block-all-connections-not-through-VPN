@echo off
:reloadTools
echo Starting up the program and verifying resources...
REM Assign a value to a variable // đặt biến
set ruleSvc=WARP Service Executable
set "warp-loc=C:\Program Files\Cloudflare\Cloudflare WARP"
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
	set killSwitchStatusCheck=Ok!
) else (
    set killSwitchStatus=Disabled
	set killSwitchStatusCheck=Bad!
)
netsh interface teredo show state | findstr /C:"disabled" >nul
IF %ERRORLEVEL% == 0 (
	set teredoStatus=Disconnected
	set teredoStatusCheck=Ok!
) ELSE (
	set teredoStatus=Connected
	set teredoStatusCheck=Bad!
)
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Disconnected" >nul
IF %ERRORLEVEL% == 0 (
	set warpStatus=Disconnected
	set warpStatusCheck=Bad!
	
) ELSE (
	set warpStatus=Connected
	set warpStatusCheck=Ok!
)
cls
REM MENU  // tuỳ chọn
echo Kill Switch (Status: %killSwitchStatus%) %killSwitchStatusCheck%
echo      Teredo (Status: %teredoStatus%) %teredoStatusCheck%
echo        WARP (Status: %warpStatus%) %warpStatusCheck%
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
echo :/menu/enable/
echo.

netsh interface teredo set state disabled >nul
echo    Microsoft Teredo Tunneling Adapter has been disabled.
warp-cli connect >nul
:warpCheckConnectLoopOn
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Connected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 >nul
	goto warpCheckConnectLoopOn
) 
echo    WARP has connected successfully.
echo.
REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    echo    Outbound rule named "%ruleSvc%" has been created. Moving on to the next step...
) else (
    netsh advfirewall firewall add rule name="%ruleSvc%" dir=out action=%action% program="%warp-svc%" enable=yes profile=%profile% >nul
    echo    Outbound Rules name="%ruleSvc%" have been successfully created.
)
REM Set inbound and outbound connections to Block for Private profile. // Đặt kết nối đầu vào và đầu ra thành Chặn cho cấu hình mạng Riêng tư.
netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound >nul
echo    Domain profile has been set to block inbound and outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound >nul
echo    Private profile has been set to block inbound and outbound connections.
netsh advfirewall set publicprofile firewallpolicy blockinbound,allowoutbound >nul
echo    Public profile has been set to block inbound, allow outbound connections.
echo.
REM Set the network profile type to Private. // Cài đặt loại cấu hình mạng thành Riêng tư.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Private" >nul
echo    Network profile type has been set to Private.
REM exclude CloudflareWARP // loại trừ con CloudflareWARP này ra phải để Public nó mới chay được
powershell -Command "Set-NetConnectionProfile -InterfaceAlias 'CloudflareWARP' -NetworkCategory Public" >nul
echo    CloudflareWARP profile type has been set to Public.
echo.
echo. & echo Enable completed.
timeout /t 4
goto menu

:off
echo :/menu/disable
echo  Restoring Windows to factory settings...
echo.
netsh interface teredo set state type=default >nul
echo    Microsoft Teredo Tunneling Adapter has been set Default.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Public" >nul
echo    Network profile type has been set to Public.
netsh advfirewall set publicprofile firewallpolicy blockinbound,allowoutbound >nul
echo    Public profile has been set to block inbound, allow outbound connections.
netsh advfirewall set domainprofile firewallpolicy blockinbound,allowoutbound >nul
echo    The domain profile has been configured to block inbound connections and allow outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,allowoutbound >nul
echo    The Private profile has been configured to block inbound connections and allow outbound connections.
netsh advfirewall firewall delete rule name="%ruleSvc%" Direction=out >nul
echo    The outbound rules has been removed.
warp-cli disconnect >nul
:warpCheckDisconnectLoopOff
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Disconnected" >nul
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 /nobreak >nul
	goto warpCheckDisconnectLoopOff
)
echo. & echo    WARP has Disconnect successfully.
echo.
echo. & echo Disable completed.
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
