#!/usr/bin/env bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$HOME/.local/bin:$PATH"

cd /home/chinhan/App_Quan_ly_chi_tieu_ca_nhan

echo "========================================================================="
echo "  📱 ĐANG KHỞI ĐỘNG MÁY ẢO ANDROID (Pixel 7 - API 34)"
echo "========================================================================="

# Kiểm tra xem máy ảo đã chạy chưa
DEVICE_READY=$(adb devices | grep -E "emulator-[0-9]+" | grep -w "device" | head -n 1)

if [ -z "$DEVICE_READY" ]; then
    echo "⚙️  Máy ảo chưa chạy. Đang khởi động máy ảo Pixel 7..."
    flutter emulators --launch Pixel_7_API_34
    
    echo "⏳ Đang đợi hệ thống Android sẵn sàng..."
    adb wait-for-device shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'
    echo "✅ Máy ảo Android đã sẵn sàng!"
else
    echo "✅ Đã phát hiện máy ảo Android đang hoạt động!"
fi

echo "========================================================================="
echo "  🚀 ĐANG CHẠY ỨNG DỤNG FLUTTER TRÊN MÁY ẢO ANDROID..."
echo "  Phím tắt: [r] Hot Reload  |  [R] Hot Restart  |  [q] Dừng ứng dụng"
echo "========================================================================="

flutter run -d Pixel_7_API_34 -t lib/main.dart

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
  echo ""
  echo "⚠️ Ứng dụng đã dừng với mã lỗi $EXIT_CODE. Nhấn Enter để đóng..."
  read -r
fi
