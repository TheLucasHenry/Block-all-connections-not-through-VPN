@echo off
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
if not %errorlevel% equ 0 (
    echo You need to run this script as an administrator.
    timeout /t 4
    exit /b
)

REM Path testing // kiểm tra đường dẫn
if not exist "%warp-loc%" (
    echo Default Cloudflare WARP folder: "C:\Program Files\Cloudflare\Cloudflare WARP"
    echo Cloudflare WARP folder not found.
    timeout /t 4
    exit
)

REM Main menu // Menu chính
:menu
cls
REM status check // kiểm tra trạng thái
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    set killSwitchStatus=Active
) else (
    set killSwitchStatus=Disabled
)
REM MENU  // tuỳ chọn
echo Kill Switch (Status: %killSwitchStatus%)
echo. & echo. Options:
echo    1. Enable
echo    2. Disable
echo    3. Ping Test
echo    4. Exit
echo.
REM To give options // đưa ra lựa chọn
choice /c 1234 /n /m "Enter your choice: "
set "choice=%errorlevel%"
cls
REM To execute a choice // thực thi lựa chọn
if "%choice%"=="1" goto on
if "%choice%"=="2" goto off
if "%choice%"=="3" goto check
if "%choice%"=="4" goto exit

:on
echo You have chosen TURN ON.
cls
echo Kill Switch Modes
echo. & echo  Please select a security mode: &echo.
echo   1. Maximum Security (Increased latency, Zero Trust, WARP updates off)
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
echo You have selected:/menu/enable/security_mode/maximum
REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleSvc%" have been created. Moving on to the next step...
) else (
    echo Outbound Rules name="%ruleSvc%" have been successfully created.
    netsh advfirewall firewall add rule name="%ruleSvc%" dir=out action=%action% program="%warp-svc%" enable=yes profile=%profile%
)
REM Set inbound and outbound connections to Block for Private profile. // Đặt kết nối đầu vào và đầu ra thành Chặn cho cấu hình mạng Riêng tư.
echo Domain profile has been set to block inbound and outbound connections.
netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound
echo Private profile has been set to block inbound and outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound
REM Set the network profile type to Private. // Cài đặt loại cấu hình mạng thành Riêng tư.
echo Network profile type has been set to Private.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Private"
echo. & echo PLEASE TURN WARP BACK ON AFTER ABOUT 5 SECONDS!
timeout /t 5 /nobreak
goto menu

:onHigh
echo You have selected:/menu/enable/security_mode/high
REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleSvc%" have been created. Moving on to the next step...
) else (
    echo Outbound Rules name="%ruleSvc%" have been successfully created.
    netsh advfirewall firewall add rule name="%ruleSvc%" dir=out action=%action% program="%warp-svc%" enable=yes profile=%profile%
)
netsh advfirewall firewall show rule name="%ruleMain%" dir=out | find /I "%ruleMain%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleMain%" have been created. Moving on to the next step...
) else (
    echo Outbound Rules name="%ruleMain%" have been successfully created.
    netsh advfirewall firewall add rule name="%ruleMain%" dir=out action=%action% program="%warp-main%" enable=yes profile=%profile%
)
REM Set inbound and outbound connections to Block for Private profile. // Đặt kết nối đầu vào và đầu ra thành Chặn cho cấu hình mạng Riêng tư.
echo Domain profile has been set to block inbound and outbound connections.
netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound
echo Private profile has been set to block inbound and outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound
REM Set the network profile type to Private. // Cài đặt loại cấu hình mạng thành Riêng tư.
echo Network profile type has been set to Private.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Private"
echo. & echo PLEASE TURN WARP BACK ON AFTER ABOUT 5 SECONDS!
timeout /t 5 /nobreak
goto menu

:onStandard
echo You have selected:/menu/enable/security_mode/standard
REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%ruleMain%" dir=out | find /I "%ruleMain%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleMain%" have been created. Moving on to the next step...
) else (
    echo Outbound Rules name="%ruleMain%" have been successfully created.
    netsh advfirewall firewall add rule name="%ruleMain%" dir=out action=%action% program="%warp-main%" enable=yes profile=%profile%
)
netsh advfirewall firewall show rule name="%ruleCli%" dir=out | find /I "%ruleCli%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleCli%"have been created. Moving on to the next step...
) else (
    echo Outbound Rules name="%ruleCli%" have been successfully created.
    netsh advfirewall firewall add rule name="%ruleCli%" dir=out action=%action% program="%warp-cli%" enable=yes profile=%profile%
)
netsh advfirewall firewall show rule name="%ruleDex%" dir=out | find /I "%ruleDex%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleDex%" have been created. Moving on to the next step...
) else (
    echo Outbound Rules name="%ruleDex%" have been successfully created.
    netsh advfirewall firewall add rule name="%ruleDex%" dir=out action=%action% program="%warp-dexi%" enable=yes profile=%profile%
)
netsh advfirewall firewall show rule name="%ruleDiag%" dir=out | find /I "%ruleDiag%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleDiag%" have been created. Moving on to the next step...
) else (
    echo Outbound Rules name="%ruleDiag%" have been successfully created.
    netsh advfirewall firewall add rule name="%ruleDiag%" dir=out action=%action% program="%warp-diag%" enable=yes profile=%profile%
)
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    echo Outbound Rules name="%ruleSvc%" have been created. Moving on to the next step...
) else (
    echo Outbound Rules name="%ruleSvc%" have been successfully created. Moving on to the next step.
    netsh advfirewall firewall add rule name="%ruleSvc%" dir=out action=%action% program="%warp-svc%" enable=yes profile=%profile%
)
REM Set inbound and outbound connections to Block for Private profile. // Đặt kết nối đầu vào và đầu ra thành Chặn cho cấu hình mạng Riêng tư.
echo Domain profile has been set to block inbound and outbound connections.
netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound
echo Private profile has been set to block inbound and outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound
REM Set the network profile type to Private. // Cài đặt loại cấu hình mạng thành Riêng tư.
echo Network profile type has been set to Private.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Private"
echo. & echo PLEASE TURN WARP BACK ON AFTER ABOUT 5 SECONDS!
timeout /t 5 /nobreak
goto menu

:off
echo You have selected:/menu/disable
echo Restore Windows to factory setting...
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Public"
echo Network profile type has been set to Public.
netsh advfirewall set domainprofile firewallpolicy blockinbound,allowoutbound
echo The domain profile has been configured to block inbound connections and allow outbound connections.
netsh advfirewall set privateprofile firewallpolicy blockinbound,allowoutbound
echo The Private profile has been configured to block inbound connections and allow outbound connections.
netsh advfirewall firewall delete rule name="%ruleMain%" Direction=out
netsh advfirewall firewall delete rule name="%ruleCli%" Direction=out
netsh advfirewall firewall delete rule name="%ruleDex%" Direction=out
netsh advfirewall firewall delete rule name="%ruleDiag%" Direction=out
netsh advfirewall firewall delete rule name="%ruleSvc%" Direction=out
echo The outbound rules has been removed.
timeout /t 4
goto menu

:check
@echo off
start "Checking connection to 8.8.8.8" cmd /k ping 8.8.8.8 -t
goto menu

:exit
echo EXIT...
exit
