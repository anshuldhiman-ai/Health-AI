@echo off
REM Starts ONLY the frontend (Vite). Useful when iterating on the UI.
REM Vite proxies /api and /health to the backend on :4000 — start the backend too for full functionality.

setlocal

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%client"

if not exist "node_modules" (
    echo [frontend] node_modules missing — running npm install ...
    call npm install
    if errorlevel 1 goto :err
)

echo [frontend] starting on http://localhost:5173 ...
call npm run dev
goto :eof

:err
echo [frontend] setup failed.
pause
exit /b 1
endlocal
