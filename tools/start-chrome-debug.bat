@echo off
REM 启动带远程调试的 Chrome（保留登录态）
REM 用法: 双击运行 或 cmd /c start-chrome-debug.bat

tasklist /FI "IMAGENAME eq chrome.exe" 2>NUL | find /I "chrome.exe" >NUL
if %ERRORLEVEL% == 0 (
    echo Chrome already running. Checking remote debugging...
    curl -s http://localhost:9333/json/version >NUL 2>&1
    if %ERRORLEVEL% == 0 (
        echo Remote debugging already enabled on port 9333.
        goto :end
    ) else (
        echo Chrome running but no remote debugging. Please close Chrome first.
        goto :end
    )
)

echo Starting Chrome with remote debugging on port 9333...
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9333 --user-data-dir="C:\Users\Administrator\AppData\Local\Google\Chrome\User Data" --no-first-run

echo Waiting for Chrome to start...
timeout /t 3 >NUL

curl -s http://localhost:9333/json/version >NUL 2>&1
if %ERRORLEVEL% == 0 (
    echo Chrome started with remote debugging enabled!
    echo Port: 9333
) else (
    echo Failed to enable remote debugging.
)

:end
pause
