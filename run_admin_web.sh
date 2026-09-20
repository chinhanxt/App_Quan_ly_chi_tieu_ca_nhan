#!/usr/bin/env bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$HOME/.local/bin:$PATH"

cd /home/chinhan/App_Quan_ly_chi_tieu_ca_nhan
echo "========================================================================="
echo "  💻 ĐANG KHỞI ĐỘNG BẢN WEB ADMIN (Desktop View - Port 8081)"
echo "  Phím tắt: [r] Hot Reload  |  [R] Hot Restart  |  [q] Dừng ứng dụng"
echo "========================================================================="
flutter run -d chrome -t lib/main_admin_web.dart \
  --web-port 8081
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "⚠️ Ứng dụng đã dừng với mã lỗi $EXIT_CODE. Nhấn Enter để đóng..."
  read -r
fi
