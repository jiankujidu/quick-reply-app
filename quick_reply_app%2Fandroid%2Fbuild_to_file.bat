@echo off
set JAVA_HOME=C:\AndroidSDK\openjdk\jdk-22.0.2
set ANDROID_HOME=C:\AndroidSDK
set PATH=%JAVA_HOME%\bin;%PATH%

cd /d "%~dp0"

echo Build started at %date% %time% > build_log.txt

"C:\ProgramData\chocolatey\lib\gradle\tools\gradle-9.4.1\bin\gradle.bat" assembleDebug --no-daemon >> build_log.txt 2>&1

set EXITCODE=%errorlevel%
echo Build finished at %date% %time% with exit code %EXITCODE% >> build_log.txt
