@echo off
REM Starts both server and client in separate windows.
REM Stops any prior instances first (uses window titles set by the per-service scripts).

setlocal

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

REM Use ports to detect any prior runs and kill them.
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":4000" ^| findstr LISTENING') do (
    echo Stopping prior server (PID %%P) on :4000 ...
    taskkill /F /PID %%P >nul 2>&1
)
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":5173" ^| findstr LISTENING') do (
    echo Stopping prior client (PID %%P) on :5173 ...
    taskkill /F /PID %%P >nul 2>&1
)

echo Starting backend on http://localhost:4000 ...
start "TradingJournal-Server" cmd /k "%PROJECT_DIR%start-backend.bat"

echo Starting frontend on http://localhost:5173 ...
start "TradingJournal-Client" cmd /k "%PROJECT_DIR%start-frontend.bat"

echo.
echo Both services starting in separate windows. Close those windows or run stop.bat to shut down.
endlocal
