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
    timeout 4
    exit /b
)

REM Path testing // kiểm tra đường dẫn
if not exist "%warp-loc%" (
	echo Default Cloudflare WARP folder: "C:\Program Files\Cloudflare\Cloudflare WARP"
	echo Cloudflare WARP folder not found.
    timeout 4
    exit
)

REM Main menu // Menu chính
:menu
cls
echo Please disable WARP to proceed!
REM List // danh sách
echo Kill Switch:
echo 1. Turn On
echo 2. Turn Off
echo 3. Check Connection
echo 4. Exit

REM To give options // đưa ra lựa chọn
choice /c 1234 /n /m "Please enter your selection (1, 2, 3, or 4): "
set "choice=%errorlevel%"

cls
REM To execute a choice // thực thi lựa chọn
if "%choice%"=="1" goto on
if "%choice%"=="2" goto off
if "%choice%"=="3" goto check
if "%choice%"=="4" goto exit

:on
echo You have chosen TURN ON.

REM Check the firewall to see if there is an outbound rule named 'Cloudflare WARP'. // Kiểm tra tường lửa xem có luật đầu ra nào tên "Cloudflare WARP" đã tồn tại chưa.
netsh advfirewall firewall show rule name="%ruleMain%" dir=out | find /I "%ruleMain%" >nul
if %errorlevel%==0 (
    echo Outbound Rules have been created. Moving on to the next step...
) else (
    echo Creating Outbound Rules...
    netsh advfirewall firewall add rule name="%ruleMain%" dir=out action=%action% program="%warp-main%" enable=yes profile=%profile%
    echo Outbound Rules have been successfully created. Moving on to the next step.
)
netsh advfirewall firewall show rule name="%ruleCli%" dir=out | find /I "%ruleCli%" >nul
if %errorlevel%==0 (
    echo Outbound Rules have been created. Moving on to the next step...
) else (
    echo Creating Outbound Rules...
    netsh advfirewall firewall add rule name="%ruleCli%" dir=out action=%action% program="%warp-cli%" enable=yes profile=%profile%
    echo Outbound Rules have been successfully created. Moving on to the next step.
)
netsh advfirewall firewall show rule name="%ruleDex%" dir=out | find /I "%ruleDex%" >nul
if %errorlevel%==0 (
    echo Outbound Rules have been created. Moving on to the next step...
) else (
    echo Creating Outbound Rules...
    netsh advfirewall firewall add rule name="%ruleDex%" dir=out action=%action% program="%warp-dexi%" enable=yes profile=%profile%
    echo Outbound Rules have been successfully created. Moving on to the next step.
)
netsh advfirewall firewall show rule name="%ruleDiag%" dir=out | find /I "%ruleDiag%" >nul
if %errorlevel%==0 (
    echo Outbound Rules have been created. Moving on to the next step...
) else (
    echo Creating Outbound Rules...
    netsh advfirewall firewall add rule name="%ruleDiag%" dir=out action=%action% program="%warp-diag%" enable=yes profile=%profile%
    echo Outbound Rules have been successfully created. Moving on to the next step.
)
netsh advfirewall firewall show rule name="%ruleSvc%" dir=out | find /I "%ruleSvc%" >nul
if %errorlevel%==0 (
    echo Outbound Rules have been created. Moving on to the next step...
) else (
    echo Creating Outbound Rules...
    netsh advfirewall firewall add rule name="%ruleSvc%" dir=out action=%action% program="%warp-svc%" enable=yes profile=%profile%
    echo Outbound Rules have been successfully created. Moving on to the next step.
)

REM Set inbound and outbound connections to Block for Private profile. // Đặt kết nối đầu vào và đầu ra thành Chặn cho cấu hình mạng Riêng tư.
netsh advfirewall set domainprofile firewallpolicy blockinbound,blockoutbound
echo Domain profile has been set to block inbound and outbound connections.

netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound
echo Private profile has been set to block inbound and outbound connections.

REM Set the network profile type to Private. // Cài đặt loại cấu hình mạng thành Riêng tư.
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Private"
echo Network profile type has been set to Private.
timeout 4
goto menu

:off
echo You have chosen TURN OFF.
echo Restore Windows to factory setting...
powershell -Command "Set-NetConnectionProfile -InterfaceAlias '*' -NetworkCategory Public"
echo Network profile type has been set to Public.

netsh advfirewall set domainprofile firewallpolicy blockinbound,allowoutbound
echo The domain profile has been configured to block incoming connections and allow outgoing ones.

netsh advfirewall set privateprofile firewallpolicy blockinbound,allowoutbound
echo The Private profile has been configured to block incoming connections and allow outgoing ones.

netsh advfirewall firewall delete rule name="%ruleMain%" Direction=out
netsh advfirewall firewall delete rule name="%ruleCli%" Direction=out
netsh advfirewall firewall delete rule name="%ruleDex%" Direction=out
netsh advfirewall firewall delete rule name="%ruleDiag%" Direction=out
netsh advfirewall firewall delete rule name="%ruleSvc%" Direction=out
echo The outbound rules has been removed.

timeout 4
goto menu

:check
@echo off
start cmd /k ping 8.8.8.8 -t
goto menu

:exit
echo EXIT...
exit
