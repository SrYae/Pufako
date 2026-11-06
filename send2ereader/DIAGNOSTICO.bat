@echo off
title Diagnostico send2ereader
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0diagnostico.ps1"
pause
