@echo off
echo ---------------------------------------------------
echo BUILD APK APP TU lib/main.dart...
echo ---------------------------------------------------
flutter build apk --release -t lib/main.dart --no-tree-shake-icons
pause
