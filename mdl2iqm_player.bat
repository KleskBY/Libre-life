@echo off
rem Player model: root motion extracted automatically per-sequence.
rem --feet-z -24: measure the animated standing feet and shift the skeleton so
rem they land exactly on the Quake player hull floor (origin is 24 above feet).
rem --split-body: also emit player_legs.iqm / player_torso.iqm for the
rem DP/Zircon two-entity upper/lower body split.
cd /d "%~dp0tools\mdl2iqm"
python mdl2iqm.py %1 --feet-z -24 --split-body --content-root "%~dp0data"
pause
