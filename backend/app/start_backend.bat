@echo off
REM Start the FastAPI backend and listen on all network interfaces.
cd /d "%~dp0"
if exist main.py (
    python main.py
) else (
    echo "main.py not found in %cd%"
)
pause