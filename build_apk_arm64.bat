@echo off
set JAVA_HOME=C:\AndroidSDK\openjdk\jdk-22.0.2
set ANDROID_HOME=C:\AndroidSDK
set PATH=%JAVA_HOME%\bin;%PATH%

cd /d "C:\Users\Administrator\.qclaw\workspace\quick-reply-app\quick_reply_app"

echo Build started at %date% %time% > build_log2.txt

C:\Flutter\flutter\bin\flutter.bat build apk --release --target-platform android-arm64 --no-pub >> build_log2.txt 2>&1

set EXITCODE=%errorlevel%
echo Build finished at %date% %time% with exit code %EXITCODE% >> build_log2.txt
