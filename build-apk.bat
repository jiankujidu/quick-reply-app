@echo off
chcp 65001 >nul
echo ========================================
echo    快回复 Pro - Flutter APK 打包脚本
echo ========================================
echo.

cd /d "%~dp0"
set FLUTTER_PATH=C:\Users\Administrator\AppData\Local\Android\flutter
set ANDROID_HOME=C:\Users\Administrator\AppData\Local\Android\Sdk

echo [1/5] 检查 Flutter 环境...
if exist "%FLUTTER_PATH%\bin\flutter.bat" (
    echo    Flutter SDK 找到
) else (
    echo    [错误] 未找到 Flutter SDK
    echo    请先安装 Flutter: https://flutter.cn/docs/get-started/install/windows
    pause
    exit /b 1
)

echo.
echo [2/5] 配置环境变量...
set PATH=%FLUTTER_PATH%\bin;%PATH%
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

echo.
echo [3/5] 获取依赖包...
call flutter pub get
if errorlevel 1 (
    echo    [错误] 依赖获取失败
    pause
    exit /b 1
)

echo.
echo [4/5] 清理构建缓存...
call flutter clean

echo.
echo [5/5] 构建 Debug APK...
call flutter build apk --debug
if errorlevel 1 (
    echo    [错误] APK 构建失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo    APK 构建成功！
echo ========================================
echo.
echo APK 文件位置：
dir /s /b "%~dp0build\app\outputs\flutter-apk\*.apk" 2>nul
echo.
echo 安装到手机：
echo   adb install "%~dp0build\app\outputs\flutter-apk\app-debug.apk"
echo.
echo 按任意键打开 APK 目录...
pause >nul
explorer "%~dp0build\app\outputs\flutter-apk"
