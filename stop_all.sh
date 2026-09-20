#!/usr/bin/env bash
echo "Đang dừng tất cả tiến trình Flutter (Mobile & Web Admin)..."
pkill -f "run -d chrome -t lib/main" 2>/dev/null || true
pkill -f "flutter_tools.snapshot run" 2>/dev/null || true
pkill -f "run_mobile.sh" 2>/dev/null || true
pkill -f "run_admin_web.sh" 2>/dev/null || true
echo "✅ Đã dừng tất cả thành công!"
