@echo off
REM Starts ONLY the backend (Express + Prisma). Useful when iterating on the API.
REM Run install/migrate the first time. cd to script's own directory so relative paths work.

setlocal

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%server"

REM First-time setup guard — if node_modules is missing, run install.
if not exist "node_modules" (
    echo [backend] node_modules missing — running npm install ...
    call npm install
    if errorlevel 1 goto :err
)

REM Generate the Prisma client and apply migrations on first run / when schema changes.
REM migrate deploy is safe to run repeatedly; it's a no-op if there are no new migrations.
echo [backend] applying Prisma migrations ...
call npx prisma migrate deploy
if errorlevel 1 goto :err

echo [backend] starting on http://localhost:4000 ...
call npm run dev
goto :eof

:err
echo [backend] setup failed.
exit /b 1
endlocal
