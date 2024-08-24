@echo off

warp-cli tunnel rotate-keys
echo    Cloudflare tunnel encryption keys have been rotated.
warp-cli connect
:warpCheckConnectLoopOn
REM Warp status check // kiểm tra trạng thái kết nối WARP
warp-cli status | findstr /C:"Connected"
IF not %ERRORLEVEL% == 0 (
	timeout /t 1 >nul
	goto warpCheckConnectLoopOn
) 
echo    WARP has connected successfully.
echo.

for /f "delims=" %%A in ('powershell -command "Get-NetIPConfiguration | Where-Object { $_.InterfaceAlias -like 'CloudflareWARP' } | Select-Object -ExpandProperty IPv4Address | Select-Object -ExpandProperty IPAddress"') do set IPAddress=%%A
echo IPv4Address of CloudflareWARP is: %IPAddress%
echo.

rem Loop through all routes with 0.0.0.0 as the destination
for /f "tokens=1-5" %%a in ('route print ^| findstr "0.0.0.0"') do (
	if "%%a" == "0.0.0.0" (
		if not "%%b" == "0.0.0.0" (
			if "%%c" == "On-link" (rem Delete the route
				if "%%d" == "%IPAddress%" (
					route delete %%a mask %%b
					echo Delete route: Network Destination: %%a, Netmask: %%b, Gateway: %%c, Interface: %%d, Metric: %%e
				)
			)
		)
	)
)

netsh interface ipv4 set interface "CloudflareWARP" metric=0
netsh interface ipv6 set interface "CloudflareWARP" metric=0
netsh interface ipv4 add route 0.0.0.0/0 metric=0 interface="CloudflareWARP" store=active
netsh interface ipv6 add route ::/0 metric=0 interface="CloudflareWARP" store=active
echo.
echo done!
timeout /t 10 >nul
exit
