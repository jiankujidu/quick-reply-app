@echo off
set "JAVA_HOME=C:\AndroidSDK\openjdk\jdk-22.0.2"
set "ANDROID_HOME=C:\AndroidSDK"
set "GRADLE_HOME=C:\ProgramData\chocolatey\lib\gradle\tools\gradle-9.4.1"
set "PATH=%GRADLE_HOME%\bin;%PATH%"
cd /d "%~dp0"
gradle.bat assembleDebug %*
