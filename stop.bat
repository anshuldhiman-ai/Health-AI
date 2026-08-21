@echo off
REM Stops the backend and frontend processes started by start.bat / start-backend.bat / start-frontend.bat.

setlocal

echo Stopping Trading Journal processes on :4000 and :5173 ...

for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":4000" ^| findstr LISTENING') do (
    echo   server PID %%P ...
    taskkill /F /PID %%P >nul 2>&1
)

for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":5173" ^| findstr LISTENING') do (
    echo   client PID %%P ...
    taskkill /F /PID %%P >nul 2>&1
)

REM Also close the title-tagged cmd windows if any are still open.
taskkill /FI "WindowTitle eq TradingJournal-Server*" /T /F >nul 2>&1
taskkill /FI "WindowTitle eq TradingJournal-Client*" /T /F >nul 2>&1

echo Done.
endlocal
