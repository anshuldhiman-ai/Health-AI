@echo off
REM Starts ONLY the backend (Express + Prisma). Useful when iterating on the API.
REM cd to script's own directory so relative paths work.

setlocal

set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%server"

REM First-time setup guard — if node_modules is missing, run install.
if not exist "node_modules" (
    echo [backend] node_modules missing — running npm install ...
    call npm install
    if errorlevel 1 goto :err
)

REM Always regenerate the Prisma client (cheap, idempotent) so the JS bindings
REM match the latest schema. --schema points at db/schema.prisma.
echo [backend] generating Prisma client ...
call npx prisma generate --schema db/schema.prisma
if errorlevel 1 goto :err

REM Apply any pending migrations. Safe to run repeatedly.
echo [backend] applying Prisma migrations ...
call npx prisma migrate deploy --schema db/schema.prisma
if errorlevel 1 goto :err

echo [backend] starting on http://localhost:4000 ...
call npm run dev
goto :eof

:err
echo [backend] setup failed.
pause
exit /b 1
endlocal
