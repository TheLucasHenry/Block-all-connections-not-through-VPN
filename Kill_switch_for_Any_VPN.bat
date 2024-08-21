@echo off
:reloadTools
echo Starting up the program and verifying resources...
REM Assign a value to a variable // đặt biến
set nameVPN=Kill_Switch_Any_VPN








::PLS CHANGE locVPN!!!!!!!
set locVPN=ENTER_YOUR_LOC
::ENTER YOUR VPN Tunnel .exe   EX:  set locVPN=C:\Program Files\Cloudflare\Cloudflare WARP\warp-svc.exe












set action=allow
set profile=any

color 0A
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
if not exist "%locVPN%" (
	cls
    echo NOT FOUND "%locVPN%"
	echo.
	echo step1: right click to .bat file and click to edit
	echo step2: find set locVPN=ENTER_YOUR_LOC line 15th
	echo step3: change 'ENTER_YOUR_LOC' into YOUR Location VPN Tunnel .exe
	echo step4: Save and Re-OPEN
	echo.
	echo EX: locVPN=C:\Program Files\Cloudflare\Cloudflare WARP\warp-svc.exe
    echo. & echo Press any key to exit...
	pause >nul
    exit
)

REM Main menu // Menu chính
:menu
REM status check // kiểm tra trạng thái
netsh advfirewall firewall show rule name="%nameVPN%" dir=out | find /I "%nameVPN%" >nul
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
cls
REM MENU  // tuỳ chọn
echo Kill Switch (Status: %killSwitchStatus%) %killSwitchStatusCheck%
echo      Teredo (Status: %teredoStatus%) %teredoStatusCheck%
echo.
echo locVPN="%locVPN%"
echo PLS TURN OFF YOUR VPN BEFORE ENABLE!
echo.
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
echo.
REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%nameVPN%" dir=out | find /I "%nameVPN%" >nul
if %errorlevel%==0 (
	netsh advfirewall firewall delete rule name="%nameVPN%" Direction=out >nul
    netsh advfirewall firewall add rule name="%nameVPN%" dir=out action=%action% program="%locVPN%" enable=yes profile=%profile% >nul
    echo    Outbound Rules name="%nameVPN%" have been successfully created.
) else (
    netsh advfirewall firewall add rule name="%nameVPN%" dir=out action=%action% program="%locVPN%" enable=yes profile=%profile% >nul
    echo    Outbound Rules name="%nameVPN%" have been successfully created.
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
echo.
echo. & echo Enable completed, You can turn on your vpn right now.
pause
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
netsh advfirewall firewall delete rule name="%nameVPN%" Direction=out >nul
echo    The outbound rules has been removed.
echo.
echo. & echo Disable completed.
pause
goto menu

:preKillSwitchTest
@echo off
start "Checking connection to 8.8.8.8" cmd /k ping 8.8.8.8 -t
goto menu

:exit
echo EXIT...
exit
