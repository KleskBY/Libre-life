@echo off
cd /d "%~dp0tools\mdl2iqm"
python mdl2iqm.py %1 --content-root "%~dp0data"
pause