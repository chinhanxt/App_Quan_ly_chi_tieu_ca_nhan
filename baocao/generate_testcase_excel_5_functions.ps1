$ErrorActionPreference = 'Stop'

$templatePath = 'C:\Users\admin\Downloads\TemplateTest.xlsx'
$outputPath = 'C:\Users\admin\Documents\VS\app\baocao\TestCase_5_ChucNang_Chuong6.xlsx'

function Clear-TestArea {
    param([object]$Sheet)
    $Sheet.Range('A8:S200').ClearContents()
}

function Set-Meta {
    param(
        [object]$Sheet,
        [string]$ProjectName,
        [string]$TestCaseName,
        [string]$Creator
    )
    $Sheet.Cells.Item(1,4).Value2 = $ProjectName
    $Sheet.Cells.Item(2,4).Value2 = $TestCaseName
    $Sheet.Cells.Item(3,4).Value2 = $Creator
    $Sheet.Cells.Item(4,4).Value2 = ''
    $Sheet.Cells.Item(5,4).Value2 = ''
}

function Write-TestCase {
    param(
        [object]$Sheet,
        [int]$StartRow,
        [string]$Id,
        [string]$Item,
        [string]$SubItem,
        [string]$Description,
        [string]$PreCondition,
        [string[]]$Steps,
        [string]$Expected,
        [string[]]$TestData
    )

    $row = $StartRow
    $maxLines = [Math]::Max($Steps.Count, [Math]::Max($TestData.Count, 1))

    for ($i = 0; $i -lt $maxLines; $i++) {
        if ($i -eq 0) {
            $Sheet.Cells.Item($row,1).Value2 = $Id
            $Sheet.Cells.Item($row,2).Value2 = $Item
            $Sheet.Cells.Item($row,3).Value2 = $SubItem
            $Sheet.Cells.Item($row,4).Value2 = $Description
            $Sheet.Cells.Item($row,5).Value2 = $PreCondition
            $Sheet.Cells.Item($row,7).Value2 = $Expected
            $Sheet.Cells.Item($row,11).Value2 = 'x'
        }

        if ($i -lt $Steps.Count) {
            $Sheet.Cells.Item($row,6).Value2 = $Steps[$i]
        }
        if ($i -lt $TestData.Count) {
            $Sheet.Cells.Item($row,8).Value2 = $TestData[$i]
        }

        $Sheet.Rows.Item($row).AutoFit() | Out-Null
        $row++
    }

    return ($row + 1)
}

$sheetsData = @(
    @{
        SheetName = '01_DangNhap'
        TestCaseName = 'Đăng nhập và xác thực'
        Cases = @(
            @{
                Id='TC01'; Item='Đăng nhập'; SubItem='Đúng thông tin'; Description='Đăng nhập đúng thông tin tài khoản'
                Pre='Đã có tài khoản user hợp lệ'
                Steps=@(
                    '1. Mở ứng dụng và truy cập màn hình đăng nhập',
                    '2. Nhập email hợp lệ',
                    '3. Nhập mật khẩu đúng',
                    '4. Nhấn nút đăng nhập'
                )
                Expected='Hệ thống xác thực thành công, kiểm tra hồ sơ và điều hướng vào dashboard đúng vai trò'
                Data=@('Email: userdemo@app.com','Mật khẩu: User@123')
            },
            @{
                Id='TC02'; Item='Đăng nhập'; SubItem='Sai mật khẩu'; Description='Đăng nhập với mật khẩu không chính xác'
                Pre='Đã có tài khoản user hợp lệ'
                Steps=@(
                    '1. Mở màn hình đăng nhập',
                    '2. Nhập email đúng',
                    '3. Nhập mật khẩu sai',
                    '4. Nhấn nút đăng nhập'
                )
                Expected='Hệ thống báo lỗi xác thực chính xác và không cho truy cập vào ứng dụng'
                Data=@('Email: userdemo@app.com','Mật khẩu sai: 123456')
            },
            @{
                Id='TC03'; Item='Đăng nhập'; SubItem='Tài khoản bị khóa'; Description='Người dùng có tài khoản đã bị admin khóa thử đăng nhập'
                Pre='Tài khoản đã bị đổi status sang locked'
                Steps=@(
                    '1. Mở màn hình đăng nhập',
                    '2. Nhập email và mật khẩu đúng của tài khoản bị khóa',
                    '3. Nhấn nút đăng nhập'
                )
                Expected='Hệ thống chặn truy cập và hiển thị thông báo tài khoản bị khóa hoặc bị hạn chế'
                Data=@('Email: locked_user@app.com','Mật khẩu: User@123')
            }
        )
    },
    @{
        SheetName = '02_GiaoDich'
        TestCaseName = 'Quản lý giao dịch thủ công'
        Cases = @(
            @{
                Id='TC04'; Item='Giao dịch thủ công'; SubItem='Thêm mới'; Description='Thêm giao dịch thủ công đầy đủ dữ liệu'
                Pre='Người dùng đã đăng nhập và đang ở dashboard'
                Steps=@(
                    '1. Mở màn hình thêm giao dịch',
                    '2. Chọn loại giao dịch',
                    '3. Nhập số tiền, danh mục, ngày và ghi chú',
                    '4. Nhấn lưu'
                )
                Expected='Giao dịch được lưu thành công, xuất hiện trong lịch sử và số dư được cập nhật'
                Data=@('Loại: debit','Số tiền: 50000','Danh mục: Ăn uống','Ghi chú: Ăn sáng')
            },
            @{
                Id='TC05'; Item='Giao dịch thủ công'; SubItem='Sửa giao dịch'; Description='Chỉnh sửa một giao dịch đã tồn tại'
                Pre='Đã có ít nhất một giao dịch trong lịch sử'
                Steps=@(
                    '1. Mở lịch sử giao dịch',
                    '2. Chọn một giao dịch cần sửa',
                    '3. Thay đổi số tiền hoặc danh mục',
                    '4. Lưu thay đổi'
                )
                Expected='Thông tin giao dịch được cập nhật và các tổng số tài chính được tính lại đúng'
                Data=@('Giao dịch cũ: 50000','Giao dịch mới: 80000')
            },
            @{
                Id='TC06'; Item='Giao dịch thủ công'; SubItem='Xóa giao dịch'; Description='Xóa một giao dịch đã tạo trước đó'
                Pre='Đã có ít nhất một giao dịch trong lịch sử'
                Steps=@(
                    '1. Mở lịch sử giao dịch',
                    '2. Chọn một giao dịch',
                    '3. Chọn xóa giao dịch',
                    '4. Xác nhận thao tác xóa'
                )
                Expected='Giao dịch bị xóa và hồ sơ tài chính được rollback đúng theo dữ liệu còn lại'
                Data=@('Giao dịch cần xóa: Mua trà sữa 30000')
            }
        )
    },
    @{
        SheetName = '03_AI_GiaoDich'
        TestCaseName = 'Ghi nhận giao dịch bằng AI'
        Cases = @(
            @{
                Id='TC07'; Item='AI Parser'; SubItem='Câu đơn'; Description='AI phân tích một câu đơn giản để tạo giao dịch'
                Pre='Người dùng đã vào màn hình AI Input'
                Steps=@(
                    '1. Mở AI Input Screen',
                    '2. Nhập câu "ăn sáng 30k"',
                    '3. Gửi nội dung cho AI',
                    '4. Quan sát card đề xuất'
                )
                Expected='AI trả về giao dịch với amount 30000, type debit và category phù hợp như Ăn uống'
                Data=@('Input: ăn sáng 30k')
            },
            @{
                Id='TC08'; Item='AI Parser'; SubItem='Câu nhiều vế'; Description='AI tách một câu có nhiều hành động thành nhiều giao dịch'
                Pre='Người dùng đã vào màn hình AI Input'
                Steps=@(
                    '1. Mở AI Input Screen',
                    '2. Nhập câu "ăn tối 50k và đổ xăng 30k"',
                    '3. Gửi nội dung cho AI',
                    '4. Kiểm tra danh sách draft'
                )
                Expected='Hệ thống tạo 2 transaction draft riêng biệt trước khi xác nhận lưu'
                Data=@('Input: ăn tối 50k và đổ xăng 30k')
            },
            @{
                Id='TC09'; Item='AI Parser'; SubItem='Câu mơ hồ'; Description='AI gặp câu chưa rõ thời gian hoặc ngữ cảnh'
                Pre='Người dùng đã vào màn hình AI Input'
                Steps=@(
                    '1. Mở AI Input Screen',
                    '2. Nhập câu "hôm trước mua đồ 200k"',
                    '3. Gửi nội dung cho AI',
                    '4. Quan sát phản hồi của hệ thống'
                )
                Expected='Hệ thống yêu cầu người dùng bổ sung thông tin nếu cần thay vì lưu sai dữ liệu'
                Data=@('Input: hôm trước mua đồ 200k')
            }
        )
    },
    @{
        SheetName = '04_NganSach'
        TestCaseName = 'Quản lý ngân sách'
        Cases = @(
            @{
                Id='TC10'; Item='Ngân sách'; SubItem='Dưới 80 phần trăm'; Description='Tạo ngân sách và thêm giao dịch nhưng vẫn dưới ngưỡng cảnh báo'
                Pre='Đã có danh mục ngân sách và người dùng đang hoạt động'
                Steps=@(
                    '1. Tạo ngân sách Ăn uống 1000000 cho tháng hiện tại',
                    '2. Thêm giao dịch 300000',
                    '3. Xem màn hình ngân sách'
                )
                Expected='Thanh tiến độ ngân sách hiển thị màu xanh do mức sử dụng còn dưới 80 phần trăm'
                Data=@('Ngân sách: 1000000','Giao dịch: 300000')
            },
            @{
                Id='TC11'; Item='Ngân sách'; SubItem='Từ 80 đến 100 phần trăm'; Description='Thêm giao dịch để ngân sách đi vào vùng cảnh báo'
                Pre='Đã có ngân sách tháng hiện tại'
                Steps=@(
                    '1. Tạo hoặc giữ ngân sách Ăn uống 1000000',
                    '2. Thêm các giao dịch để tổng chi đạt 900000',
                    '3. Xem màn hình ngân sách'
                )
                Expected='Thanh tiến độ đổi sang màu cam hoặc vàng khi mức sử dụng đạt vùng 80 đến 100 phần trăm'
                Data=@('Ngân sách: 1000000','Tổng chi: 900000')
            },
            @{
                Id='TC12'; Item='Ngân sách'; SubItem='Vượt ngân sách'; Description='Thêm giao dịch vượt quá hạn mức ngân sách'
                Pre='Đã có ngân sách tháng hiện tại'
                Steps=@(
                    '1. Đặt ngân sách Ăn uống 1000000',
                    '2. Thêm các giao dịch để tổng chi vượt 1000000',
                    '3. Xem màn hình ngân sách'
                )
                Expected='Thanh tiến độ chuyển sang màu đỏ và hiển thị mức vượt ngân sách'
                Data=@('Ngân sách: 1000000','Tổng chi: 1200000')
            }
        )
    },
    @{
        SheetName = '05_Admin'
        TestCaseName = 'Quản trị hệ thống'
        Cases = @(
            @{
                Id='TC13'; Item='Admin'; SubItem='Khóa user'; Description='Admin khóa tài khoản người dùng đang hoạt động'
                Pre='Admin đã đăng nhập web admin và user mục tiêu tồn tại'
                Steps=@(
                    '1. Mở Users Page',
                    '2. Tìm user cần khóa',
                    '3. Chọn thao tác khóa tài khoản',
                    '4. Quan sát phản hồi trên client của user'
                )
                Expected='User bị đổi trạng thái, client đang lắng nghe nhận cập nhật mới và bị chặn truy cập'
                Data=@('User mục tiêu: userdemo@app.com')
            },
            @{
                Id='TC14'; Item='Admin'; SubItem='Thêm broadcast'; Description='Admin tạo một broadcast mới cho hệ thống'
                Pre='Admin đã đăng nhập web admin'
                Steps=@(
                    '1. Mở Broadcasts Page',
                    '2. Tạo broadcast mới',
                    '3. Nhập tiêu đề, nội dung và trạng thái hoạt động',
                    '4. Lưu broadcast'
                )
                Expected='Broadcast được lưu thành công và các client liên quan có thể đọc dữ liệu mới theo luồng realtime'
                Data=@('Tiêu đề: Bảo trì hệ thống','Nội dung: Bảo trì lúc 22h')
            },
            @{
                Id='TC15'; Item='Admin'; SubItem='Publish AI runtime'; Description='Admin thay đổi cấu hình runtime AI và publish'
                Pre='Admin đã đăng nhập web admin và có quyền cấu hình AI'
                Steps=@(
                    '1. Mở AI Config Page',
                    '2. Chỉnh runtime draft hoặc prompt',
                    '3. Preview bằng một câu giao dịch mẫu',
                    '4. Publish cấu hình mới'
                )
                Expected='Cấu hình mới được ghi vào system_configs và có log quản trị tương ứng'
                Data=@('Prompt mẫu: ăn sáng 30k','Runtime: draft mới')
            }
        )
    }
)

$excel = $null
$wb = $null

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    $wb = $excel.Workbooks.Open($templatePath)

    $baseSheet = $wb.Worksheets.Item(1)
    $baseSheet.Name = $sheetsData[0].SheetName

    for ($i = 1; $i -lt $sheetsData.Count; $i++) {
        $baseSheet.Copy([System.Type]::Missing, $wb.Worksheets.Item($wb.Worksheets.Count))
        $wb.Worksheets.Item($wb.Worksheets.Count).Name = $sheetsData[$i].SheetName
    }

    for ($i = $wb.Worksheets.Count; $i -ge 1; $i--) {
        $ws = $wb.Worksheets.Item($i)
        if ($ws.Name -eq 'Sheet1') {
            $ws.Delete()
        }
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws) | Out-Null
    }

    foreach ($sheetInfo in $sheetsData) {
        $ws = $wb.Worksheets.Item($sheetInfo.SheetName)
        Clear-TestArea -Sheet $ws
        Set-Meta -Sheet $ws -ProjectName 'He thong quan ly tai chinh ca nhan thong minh' -TestCaseName $sheetInfo.TestCaseName -Creator 'Codex'

        $nextRow = 8
        foreach ($case in $sheetInfo.Cases) {
            $nextRow = Write-TestCase -Sheet $ws -StartRow $nextRow -Id $case.Id -Item $case.Item -SubItem $case.SubItem -Description $case.Description -PreCondition $case.Pre -Steps $case.Steps -Expected $case.Expected -TestData $case.Data
        }

        $ws.Columns.AutoFit() | Out-Null
        $ws.Rows.AutoFit() | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($ws) | Out-Null
    }

    $wb.SaveAs($outputPath)
    $wb.Close($true)
    $excel.Quit()

    Write-Output "Created: $outputPath"
}
catch {
    if ($wb -ne $null) { $wb.Close($false) }
    if ($excel -ne $null) { $excel.Quit() }
    throw
}
finally {
    if ($baseSheet -ne $null) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($baseSheet) | Out-Null }
    if ($wb -ne $null) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wb) | Out-Null }
    if ($excel -ne $null) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null }
}
