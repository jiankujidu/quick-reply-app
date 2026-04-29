@echo off
set JAVA_HOME=C:\AndroidSDK\openjdk\jdk-22.0.2
set ANDROID_HOME=C:\AndroidSDK
set PATH=%JAVA_HOME%\bin;C:\Flutter\flutter\bin;%PATH%
cd /d C:\Users\Administrator\.qclaw\workspace\quick-reply-app
C:\Flutter\flutter\bin\flutter.bat build apk --debug
