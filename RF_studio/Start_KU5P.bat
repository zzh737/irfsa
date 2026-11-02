@echo off
setlocal
cd /d "%~dp0"
if exist "%~dp0KU5P_Radio_Studio.exe" (
    start "" "%~dp0KU5P_Radio_Studio.exe"
    exit /b 0
)
if exist "D:\Python\pythonw.exe" (
    start "" "D:\Python\pythonw.exe" "%~dp0app.py"
    exit /b 0
)
where pyw >nul 2>nul
if not errorlevel 1 (
    start "" pyw -3 "%~dp0app.py"
    exit /b 0
)
python "%~dp0app.py"
if errorlevel 1 pause
