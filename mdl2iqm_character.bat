@echo off
rem Root motion is now extracted automatically per-sequence (STUDIO_LX/LY/LZ
rem flags from the MDL), and bodygroups/skin families generate .skin +
rem .bodyinfo sidecars next to the IQM. No --inplace needed.
cd /d "%~dp0tools\mdl2iqm"
python mdl2iqm.py %1 --content-root "%~dp0data"
pause
