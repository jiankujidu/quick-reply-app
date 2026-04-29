@echo off
set "JAVA_HOME=C:\AndroidSDK\openjdk\jdk-22.0.2"
set "ANDROID_HOME=C:\AndroidSDK"
set "GRADLE_HOME=C:\ProgramData\chocolatey\lib\gradle\tools\gradle-9.4.1"
set "PATH=C:\ProgramData\chocolatey\lib\gradle\tools\gradle-9.4.1\bin;%PATH%"
echo Building APK with Gradle 9.4.1
cd /d "C:\Users\Administrator\.qclaw\workspace\quick-reply-app\quick_reply_app"
call C:\Flutter\flutter\bin\flutter.bat build apk --debug 2>&1
