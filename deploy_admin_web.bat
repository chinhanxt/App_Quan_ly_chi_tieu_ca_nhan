@echo off
echo ---------------------------------------------------
echo BUILD ADMIN WEB KHONG CAT ICON...
echo ---------------------------------------------------
flutter build web --release -t lib/main_admin_web.dart --no-tree-shake-icons
if errorlevel 1 pause & exit /b 1

echo ---------------------------------------------------
echo DEPLOY ADMIN WEB LEN FIREBASE HOSTING...
echo ---------------------------------------------------
firebase deploy --only hosting
pause
