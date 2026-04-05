$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$outputPath = "C:\Users\admin\Documents\VS\app\baocao\bang_mo_ta_so_do_tu_so_do.docx"
$templatePath = "C:\Users\admin\Documents\VS\app\baocao\bang_erd_quy_doi_thuc_the.docx"

function Escape-Xml {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    return [System.Security.SecurityElement]::Escape($Text)
}

function New-RunXml {
    param(
        [string]$Text,
        [bool]$Bold = $false
    )
    $escaped = Escape-Xml $Text
    if ($Bold) {
        return "<w:r><w:rPr><w:b/></w:rPr><w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
    }
    return "<w:r><w:t xml:space=`"preserve`">$escaped</w:t></w:r>"
}

function New-ParagraphXml {
    param(
        [string]$Text,
        [string]$Justification = 'left',
        [bool]$Bold = $false
    )
    $run = New-RunXml -Text $Text -Bold $Bold
    return "<w:p><w:pPr><w:jc w:val=`"$Justification`"/></w:pPr>$run</w:p>"
}

function New-TableCellXml {
    param(
        [string]$Text,
        [bool]$Bold = $false,
        [string]$Width = '2400',
        [switch]$Header
    )
    $shading = ''
    if ($Header) {
        $shading = '<w:shd w:val="clear" w:color="auto" w:fill="D9D9D9"/>'
    }
    $run = New-RunXml -Text $Text -Bold $Bold
    return "<w:tc><w:tcPr><w:tcW w:w=`"$Width`" w:type=`"dxa`"/>$shading</w:tcPr><w:p>$run</w:p></w:tc>"
}

function New-NarrativeTableXml {
    param(
        [hashtable]$Rows
    )
    $xml = '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/></w:tblBorders></w:tblPr>'
    foreach ($key in $Rows.Keys) {
        $xml += '<w:tr>'
        $xml += New-TableCellXml -Text $key -Bold $true -Width '2200'
        $xml += New-TableCellXml -Text $Rows[$key] -Width '6800'
        $xml += '</w:tr>'
    }
    $xml += '</w:tbl>'
    return $xml
}

function New-EntityTableXml {
    param(
        [array]$Fields
    )
    $xml = '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/></w:tblBorders></w:tblPr>'
    $xml += '<w:tr>'
    $xml += New-TableCellXml -Text 'STT' -Bold $true -Width '900' -Header
    $xml += New-TableCellXml -Text 'Thuộc tính' -Bold $true -Width '2500' -Header
    $xml += New-TableCellXml -Text 'Mô tả ngắn' -Bold $true -Width '5600' -Header
    $xml += '</w:tr>'
    for ($i = 0; $i -lt $Fields.Count; $i++) {
        $xml += '<w:tr>'
        $xml += New-TableCellXml -Text ([string]($i + 1)) -Width '900'
        $xml += New-TableCellXml -Text $Fields[$i][0] -Width '2500'
        $xml += New-TableCellXml -Text $Fields[$i][1] -Width '5600'
        $xml += '</w:tr>'
    }
    $xml += '</w:tbl>'
    return $xml
}

$useCaseTables = @(
    @{
        Title = 'Bảng mô tả sơ đồ Tổng Quát'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'Tổng Quát'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả phạm vi chức năng chung của toàn hệ thống cho hai actor User và Admin.'
            'Thành phần chính' = 'Actor User, actor Admin, các use case đăng nhập chung, quản lý tài khoản, giao dịch, danh mục, ngân sách, mục tiêu tiết kiệm, báo cáo, quản trị dữ liệu, AI runtime và giám sát.'
            'Luồng mô tả' = 'User truy cập các chức năng nghiệp vụ cá nhân; Admin truy cập các chức năng quản trị; nhiều nhánh đều bao gồm bước đăng nhập chung trước khi đi vào chức năng chi tiết.'
            'Ý nghĩa trong hệ thống' = 'Là sơ đồ bao quát nhất, giúp người đọc nhìn được ranh giới giữa phân hệ người dùng và phân hệ quản trị.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ User_Phân Rã'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'User_Phân Rã'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Phân rã toàn bộ nhóm chức năng phía người dùng thành các mảng nghiệp vụ nhỏ hơn.'
            'Thành phần chính' = 'Actor User, các nhóm use case quản lý tài khoản, giao dịch, danh mục, ngân sách, mục tiêu tiết kiệm, báo cáo và cài đặt.'
            'Luồng mô tả' = 'User đi từ các nhóm chức năng lớn đến các nhánh bao gồm như quản lý hồ sơ, ghi nhận dòng tiền, thiết lập hạn mức vi mô, lập kế hoạch tiết kiệm, giám sát biểu đồ và tùy biến ứng dụng.'
            'Ý nghĩa trong hệ thống' = 'Làm rõ phạm vi nghiệp vụ của mobile app và là cầu nối từ sơ đồ tổng quát sang các sơ đồ user chi tiết.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ Admin_Phân Rã'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'Admin_Phân Rã'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Phân rã nhóm chức năng quản trị thành các khối truy cập, quản lý dữ liệu, AI runtime và giám sát tổng.'
            'Thành phần chính' = 'Actor Admin, các use case truy cập hệ thống, quản lý người dùng, quản lý CSDL, quản lý AI runtime và giám sát tổng.'
            'Luồng mô tả' = 'Admin đăng nhập và từ đó thực hiện xác thực đa tầng, quản lý tài khoản, thiết lập phân quyền, bảo trì hệ thống, xem log AI, vận hành cấu hình AI và theo dõi số lượng toàn cục.'
            'Ý nghĩa trong hệ thống' = 'Cho thấy phân hệ admin không chỉ xem dữ liệu mà còn có vai trò vận hành, giám sát và can thiệp hệ thống.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ User_Quản Lý Tài Khoản'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'User_Quản Lý Tài Khoản'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các thao tác liên quan đến vòng đời tài khoản người dùng.'
            'Thành phần chính' = 'Actor User, use case quản lý tài khoản, đăng ký, đăng nhập, quên mật khẩu, đăng xuất, cập nhật hồ sơ.'
            'Luồng mô tả' = 'User đi vào use case quản lý tài khoản và từ đó thực hiện các thao tác xác thực hoặc cập nhật hồ sơ cá nhân.'
            'Ý nghĩa trong hệ thống' = 'Xác định điểm vào của người dùng vào ứng dụng và nhóm chức năng bảo trì hồ sơ cơ bản.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ User_Quản Lý Giao Dịch'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'User_Quản Lý Giao Dịch'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các cách người dùng tạo và quản lý giao dịch thu chi.'
            'Thành phần chính' = 'Actor User, use case quản lý giao dịch, thêm giao dịch thủ công, thêm bằng AI, thêm bằng OCR, sửa, xóa, xem lịch sử, tìm kiếm và lọc.'
            'Luồng mô tả' = 'Từ use case trung tâm quản lý giao dịch, User có thể tạo mới theo nhiều cách hoặc xem, lọc, chỉnh sửa và xóa giao dịch đã có.'
            'Ý nghĩa trong hệ thống' = 'Đây là sơ đồ lõi của sản phẩm vì giao dịch là dữ liệu trung tâm chi phối báo cáo, ngân sách và số dư.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ User_Quản Lý Danh Mục'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'User_Quản Lý Danh Mục'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả cách người dùng tự quản lý danh mục cá nhân phục vụ nhập liệu giao dịch.'
            'Thành phần chính' = 'Actor User, use case quản lý danh mục, tạo, sửa, xóa danh mục cá nhân và chọn danh mục khi tạo giao dịch.'
            'Luồng mô tả' = 'User thao tác với danh mục riêng để điều chỉnh cấu trúc phân loại thu chi và sử dụng lại khi ghi nhận giao dịch.'
            'Ý nghĩa trong hệ thống' = 'Bảo đảm ứng dụng linh hoạt theo từng người dùng thay vì chỉ phụ thuộc vào danh mục mặc định toàn hệ thống.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ User_Quản Lý Ngân Sách'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'User_Quản Lý Ngân Sách'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các thao tác thiết lập và theo dõi ngân sách chi tiêu theo danh mục.'
            'Thành phần chính' = 'Actor User, use case quản lý ngân sách, tạo ngân sách tháng, theo dõi mức chi, nhận cảnh báo vượt ngưỡng, xóa ngân sách.'
            'Luồng mô tả' = 'User thiết lập hạn mức, hệ thống đối chiếu mức chi theo danh mục và phát cảnh báo khi gần chạm hoặc vượt ngưỡng.'
            'Ý nghĩa trong hệ thống' = 'Liên kết trực tiếp giữa giao dịch phát sinh và khả năng kiểm soát chi tiêu của người dùng.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ User_Quản Lý Mục Tiêu Tiết Kiệm'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'User_Quản Lý Mục Tiêu Tiết Kiệm'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các thao tác tạo, nạp tiền, rút tiền và theo dõi tiến độ mục tiêu tiết kiệm.'
            'Thành phần chính' = 'Actor User, use case quản lý mục tiêu tiết kiệm, tạo mục tiêu, nạp tiền vào mục tiêu, rút tiền, đóng mục tiêu, theo dõi tiến độ.'
            'Luồng mô tả' = 'User thiết lập mục tiêu, cập nhật dòng tiền đóng góp và quan sát mức hoàn thành cho từng mục tiêu tiết kiệm.'
            'Ý nghĩa trong hệ thống' = 'Tăng chiều sâu cho sản phẩm, mở rộng từ quản lý chi tiêu sang quản lý tích lũy tài chính cá nhân.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ User_Báo Cáo Và Cài Đặt'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'User_Báo Cáo Và Cài Đặt'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các chức năng xem báo cáo và điều chỉnh thiết lập phía người dùng.'
            'Thành phần chính' = 'Actor User, use case báo cáo và cài đặt, xem thông báo hệ thống, xem phân tích theo danh mục, xem báo cáo tháng, xem giao dịch lớn nhất hoặc nhỏ nhất, xuất PDF, cài đặt giao diện.'
            'Luồng mô tả' = 'User đi vào khu báo cáo và cài đặt để đọc số liệu, xem các phân tích tài chính và điều chỉnh trải nghiệm giao diện của ứng dụng.'
            'Ý nghĩa trong hệ thống' = 'Là đầu ra trực quan của dữ liệu giao dịch và ngân sách, giúp người dùng chuyển từ ghi nhận sang phân tích.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ Admin_Truy Cập Hệ Thống'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'Admin_Truy Cập Hệ Thống'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả luồng truy cập cơ bản của quản trị viên vào cổng quản trị.'
            'Thành phần chính' = 'Actor Admin, use case truy cập hệ thống, đăng nhập admin, kiểm tra role, kiểm tra permission, đăng xuất.'
            'Luồng mô tả' = 'Admin đăng nhập, hệ thống kiểm tra vai trò và quyền, sau đó mới cho phép vào khu quản trị và hỗ trợ đăng xuất an toàn.'
            'Ý nghĩa trong hệ thống' = 'Thiết lập lớp kiểm soát đầu vào cho toàn bộ chức năng quản trị.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ Admin_Quản Lý Người Dùng'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'Admin_Quản Lý Người Dùng'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các tác vụ quản trị tài khoản người dùng trên web admin.'
            'Thành phần chính' = 'Actor Admin, use case quản lý người dùng, xem danh sách user, tìm kiếm user, khóa tài khoản, mở khóa tài khoản, xem trạng thái tài khoản, gán role admin, phân quyền chi tiết.'
            'Luồng mô tả' = 'Admin truy cập module người dùng để tra cứu, đánh giá trạng thái và thay đổi quyền hoặc khả năng truy cập của từng tài khoản.'
            'Ý nghĩa trong hệ thống' = 'Là trung tâm cho chức năng kiểm soát vận hành và an toàn tài khoản ở phía quản trị.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ Admin_Quản Lý Dữ Liệu Hệ Thống'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'Admin_Quản Lý Dữ Liệu Hệ Thống'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các nhóm dữ liệu vận hành mà admin có quyền quản lý.'
            'Thành phần chính' = 'Actor Admin, use case quản lý dữ liệu hệ thống, quản lý thông tin hỗ trợ liên hệ, quản lý danh mục hệ thống, quản lý thông báo hệ thống, quản lý cấu hình hệ thống.'
            'Luồng mô tả' = 'Admin làm việc với các dữ liệu dùng chung để điều chỉnh cách hệ thống hoạt động và những gì người dùng cuối nhìn thấy.'
            'Ý nghĩa trong hệ thống' = 'Thể hiện chiều sâu vận hành của cổng admin chứ không chỉ dừng ở xem dashboard.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ Admin_Quản Lý AI'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'Admin_Quản Lý AI'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các thao tác quản trị cấu hình AI runtime và lexicon trên web admin.'
            'Thành phần chính' = 'Actor Admin, use case quản lý AI runtime, publish AI runtime config, xem runtime config hiện hành, lưu draft runtime config, quản lý lexicon AI, ghi log thao tác admin.'
            'Luồng mô tả' = 'Admin điều chỉnh cấu hình AI, lưu nháp, xem cấu hình hiện hành, publish bản chạy và theo dõi log liên quan đến AI.'
            'Ý nghĩa trong hệ thống' = 'Cho thấy AI trong hệ thống được vận hành chủ động, có quy trình draft/publish và giám sát thay vì là khối logic cố định.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ Admin_Giám Sát Và Báo Cáo'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'Admin_Giám Sát Và Báo Cáo'
            'Loại sơ đồ' = 'Use case'
            'Mục đích' = 'Mô tả các thao tác theo dõi dữ liệu tổng quan và báo cáo toàn hệ thống của quản trị viên.'
            'Thành phần chính' = 'Actor Admin, use case giám sát và báo cáo, xem dashboard tổng quan, xem giao dịch toàn hệ thống, xóa giao dịch mức quản trị, xem báo cáo tổng hợp tháng.'
            'Luồng mô tả' = 'Admin quan sát dữ liệu vận hành, truy vết giao dịch toàn cục và xem báo cáo để đưa ra can thiệp quản trị phù hợp.'
            'Ý nghĩa trong hệ thống' = 'Là sơ đồ thể hiện vai trò giám sát hệ thống ở mức toàn cục của admin.'
        }
    },
    @{
        Title = 'Bảng mô tả sơ đồ Cấu trúc Cloud Firestore'
        Rows = [ordered]@{
            'Tên sơ đồ' = 'Cấu trúc Cloud Firestore'
            'Loại sơ đồ' = 'Firestore structure'
            'Mục đích' = 'Mô tả cách tổ chức collection, document và subcollection trong cơ sở dữ liệu Firestore của hệ thống.'
            'Thành phần chính' = 'Collection users, document {uid}, các subcollection budgets, transactions, saving_goals, contributions, và các collection dùng chung system_configs, categories, system_broadcasts, admin_logs.'
            'Luồng mô tả' = 'Dữ liệu cá nhân được neo dưới document người dùng, còn dữ liệu vận hành toàn hệ thống được tách thành các collection dùng chung để admin và ứng dụng cùng khai thác.'
            'Ý nghĩa trong hệ thống' = 'Giúp người đọc hiểu cách chuyển từ tư duy NoSQL Firestore sang ERD logic và class diagram ở các phần sau.'
        }
    }
)

$classTables = @(
    @{ Title = 'Bảng mô tả lớp User'; Fields = @(@('uid', 'Mã định danh của đối tượng người dùng trong tầng ứng dụng'), @('name', 'Tên hiển thị của người dùng'), @('email', 'Email dùng để xác thực và liên hệ'), @('phone', 'Số điện thoại hỗ trợ nhận diện hoặc liên hệ'), @('role', 'Vai trò nghiệp vụ như user hoặc admin'), @('status', 'Trạng thái tài khoản như active hoặc locked'), @('totalCredit', 'Tổng thu tích lũy được lớp User quản lý'), @('totalDebit', 'Tổng chi tích lũy được lớp User quản lý'), @('remainingAmount', 'Số dư hiện tại của người dùng'), @('createdAt', 'Thời điểm khởi tạo đối tượng người dùng')) }
    @{ Title = 'Bảng mô tả lớp Transaction'; Fields = @(@('transactionId', 'Mã giao dịch trong tầng nghiệp vụ'), @('title', 'Tiêu đề ngắn của giao dịch'), @('amount', 'Giá trị tiền của giao dịch'), @('type', 'Loại dòng tiền như credit hoặc debit'), @('note', 'Ghi chú nghiệp vụ đi kèm giao dịch'), @('timestamp', 'Mốc thời gian của giao dịch'), @('monthyear', 'Nhãn tháng năm hỗ trợ gom nhóm báo cáo')) }
    @{ Title = 'Bảng mô tả lớp Budget'; Fields = @(@('budgetId', 'Mã nhận diện ngân sách'), @('categoryName', 'Danh mục được áp dụng hạn mức'), @('limitAmount', 'Mức chi tối đa được phép trong kỳ'), @('monthyear', 'Kỳ tháng năm mà ngân sách có hiệu lực'), @('createdAt', 'Thời điểm tạo ngân sách')) }
    @{ Title = 'Bảng mô tả lớp SavingGoal'; Fields = @(@('goalId', 'Mã nhận diện mục tiêu tiết kiệm'), @('goalName', 'Tên mục tiêu do người dùng đặt'), @('targetAmount', 'Số tiền mục tiêu cần đạt'), @('currentAmount', 'Số tiền đã tích lũy hiện tại'), @('startDate', 'Ngày bắt đầu mục tiêu'), @('targetDate', 'Ngày đích dự kiến hoàn thành'), @('status', 'Trạng thái mục tiêu như active hoặc closed'), @('icon', 'Biểu tượng hiển thị cho mục tiêu'), @('color', 'Màu đại diện dùng trên giao diện')) }
    @{ Title = 'Bảng mô tả lớp Contribution'; Fields = @(@('contributionId', 'Mã của một lần đóng góp vào mục tiêu'), @('amount', 'Số tiền đóng góp'), @('type', 'Kiểu nghiệp vụ như nạp thêm hoặc rút bớt'), @('note', 'Ghi chú giải thích giao dịch đóng góp'), @('createdAt', 'Thời điểm ghi nhận đóng góp')) }
    @{ Title = 'Bảng mô tả lớp QuickTemplate'; Fields = @(@('templateId', 'Mã mẫu giao dịch nhanh'), @('label', 'Nhãn hiển thị ngắn trên giao diện'), @('title', 'Tiêu đề giao dịch mặc định'), @('amount', 'Giá trị tiền gợi ý của mẫu'), @('type', 'Loại thu hoặc chi của mẫu'), @('category', 'Danh mục gắn với mẫu'), @('note', 'Ghi chú mặc định khi áp dụng mẫu')) }
    @{ Title = 'Bảng mô tả lớp UserCategory'; Fields = @(@('categoryId', 'Mã định danh danh mục cá nhân'), @('name', 'Tên danh mục'), @('type', 'Loại danh mục như thu hoặc chi'), @('iconName', 'Tên icon dùng để hiển thị'), @('isDefault', 'Cho biết danh mục có phải mặc định hay không')) }
    @{ Title = 'Bảng mô tả lớp SystemBroadcast'; Fields = @(@('broadcastId', 'Mã thông báo hệ thống'), @('title', 'Tiêu đề thông báo'), @('content', 'Nội dung chi tiết được phát ra'), @('type', 'Loại thông báo như info hoặc warning'), @('status', 'Trạng thái hiển thị hay lưu nháp'), @('createdByEmail', 'Email admin phát thông báo')) }
    @{ Title = 'Bảng mô tả lớp SystemConfig'; Fields = @(@('configId', 'Mã cấu hình hệ thống'), @('configData', 'Dữ liệu cấu hình tổng hợp của một module')) }
    @{ Title = 'Bảng mô tả lớp GlobalCategory'; Fields = @(@('globalCategoryId', 'Mã danh mục dùng chung toàn hệ thống'), @('name', 'Tên danh mục toàn cục'), @('type', 'Loại danh mục thu hoặc chi'), @('iconName', 'Icon hiển thị cho danh mục mặc định')) }
    @{ Title = 'Bảng mô tả lớp AdminLog'; Fields = @(@('logId', 'Mã nhật ký quản trị'), @('action', 'Hành động mà admin đã thực hiện'), @('target', 'Đối tượng bị tác động bởi hành động'), @('adminUid', 'Mã admin thực hiện thao tác'), @('adminEmail', 'Email admin thực hiện thao tác'), @('createdAt', 'Thời điểm tạo bản ghi log')) }
)

$erdTables = @(
    @{ Title = 'Bảng thực thể User'; Fields = @(@('user_id', 'Khóa chính định danh duy nhất người dùng'), @('name', 'Tên hiển thị của người dùng'), @('email', 'Email đăng nhập và liên hệ'), @('phone', 'Số điện thoại của người dùng'), @('role', 'Vai trò như user hoặc admin'), @('status', 'Trạng thái tài khoản như active hoặc locked'), @('totalCredit', 'Tổng thu được tổng hợp cho người dùng'), @('totalDebit', 'Tổng chi được tổng hợp cho người dùng'), @('remainingAmount', 'Số dư hiện tại của người dùng'), @('createdAt', 'Thời điểm tạo tài khoản')) }
    @{ Title = 'Bảng thực thể Transaction'; Fields = @(@('transaction_id', 'Khóa chính của giao dịch'), @('user_id', 'Khóa ngoại tham chiếu người dùng sở hữu giao dịch'), @('title', 'Tên giao dịch'), @('amount', 'Số tiền của giao dịch'), @('type', 'Loại giao dịch credit hoặc debit'), @('category', 'Danh mục giao dịch'), @('note', 'Ghi chú chi tiết'), @('timestamp', 'Thời điểm phát sinh giao dịch'), @('monthyear', 'Kỳ tháng năm để tổng hợp báo cáo')) }
    @{ Title = 'Bảng thực thể Budget'; Fields = @(@('budget_id', 'Khóa chính của ngân sách'), @('user_id', 'Khóa ngoại tham chiếu chủ sở hữu ngân sách'), @('categoryName', 'Danh mục áp dụng hạn mức'), @('limitAmount', 'Mức chi tối đa trong kỳ'), @('monthyear', 'Tháng năm áp dụng'), @('createdAt', 'Thời điểm tạo bản ghi ngân sách')) }
    @{ Title = 'Bảng thực thể SavingGoal'; Fields = @(@('goal_id', 'Khóa chính của mục tiêu tiết kiệm'), @('user_id', 'Khóa ngoại tham chiếu người dùng tạo mục tiêu'), @('goal_name', 'Tên mục tiêu tiết kiệm'), @('target_amount', 'Số tiền mục tiêu cần đạt'), @('current_amount', 'Số tiền hiện đã tích lũy'), @('start_date', 'Ngày bắt đầu mục tiêu'), @('target_date', 'Ngày đích dự kiến'), @('status', 'Trạng thái mục tiêu'), @('icon', 'Biểu tượng đại diện'), @('color', 'Màu nhận diện trên giao diện'), @('created_at', 'Thời điểm tạo mục tiêu')) }
    @{ Title = 'Bảng thực thể Contribution'; Fields = @(@('contribution_id', 'Khóa chính của lần đóng góp'), @('goal_id', 'Khóa ngoại tham chiếu mục tiêu tiết kiệm'), @('user_id', 'Khóa ngoại tham chiếu người dùng thực hiện đóng góp'), @('amount', 'Số tiền đóng góp hoặc rút'), @('type', 'Loại nghiệp vụ của đóng góp'), @('note', 'Ghi chú cho lần đóng góp'), @('createdAt', 'Thời điểm tạo bản ghi đóng góp')) }
    @{ Title = 'Bảng thực thể QuickTemplate'; Fields = @(@('template_id', 'Khóa chính của mẫu giao dịch nhanh'), @('user_id', 'Khóa ngoại tham chiếu người dùng sở hữu mẫu'), @('label', 'Nhãn ngắn của mẫu'), @('title', 'Tiêu đề giao dịch mặc định'), @('amount', 'Số tiền gợi ý'), @('type', 'Loại giao dịch mặc định'), @('category', 'Danh mục áp dụng cho mẫu'), @('note', 'Ghi chú đi kèm'), @('iconName', 'Icon đại diện cho mẫu')) }
    @{ Title = 'Bảng thực thể UserCategory'; Fields = @(@('category_id', 'Khóa chính của danh mục cá nhân'), @('user_id', 'Khóa ngoại tham chiếu người dùng sở hữu danh mục'), @('name', 'Tên danh mục'), @('type', 'Loại danh mục thu hoặc chi'), @('iconName', 'Tên icon hiển thị'), @('isDefault', 'Cờ cho biết danh mục mặc định hay do người dùng tạo'), @('updatedAt', 'Thời điểm cập nhật gần nhất')) }
    @{ Title = 'Bảng thực thể GlobalCategory'; Fields = @(@('global_category_id', 'Khóa chính của danh mục toàn hệ thống'), @('name', 'Tên danh mục mặc định'), @('type', 'Loại danh mục thu hoặc chi'), @('iconName', 'Icon hiển thị của danh mục'), @('createdAt', 'Thời điểm tạo danh mục'), @('updatedAt', 'Thời điểm cập nhật gần nhất')) }
    @{ Title = 'Bảng thực thể SystemBroadcast'; Fields = @(@('broadcast_id', 'Khóa chính của thông báo hệ thống'), @('title', 'Tiêu đề thông báo'), @('content', 'Nội dung chi tiết'), @('type', 'Loại thông báo'), @('status', 'Trạng thái phát hành'), @('createdAt', 'Thời điểm tạo thông báo'), @('updatedAt', 'Thời điểm cập nhật thông báo'), @('createdByEmail', 'Email admin đã tạo thông báo')) }
    @{ Title = 'Bảng thực thể SystemConfig'; Fields = @(@('config_id', 'Khóa chính của cấu hình hệ thống'), @('configData', 'Dữ liệu cấu hình được lưu dưới dạng tổng hợp')) }
    @{ Title = 'Bảng thực thể AdminLog'; Fields = @(@('log_id', 'Khóa chính của bản ghi log quản trị'), @('action', 'Hành động được thực hiện'), @('target', 'Đối tượng bị tác động'), @('adminUid', 'Mã admin thực hiện thao tác'), @('adminEmail', 'Email admin thực hiện thao tác'), @('createdAt', 'Thời điểm tạo log')) }
)

try {
    $tempRoot = Join-Path $env:TEMP ("diagram_desc_" + [guid]::NewGuid().ToString())
    $zipPath = "$tempRoot.zip"
    $templateCopyPath = Join-Path $env:TEMP ("diagram_template_" + [guid]::NewGuid().ToString() + '.docx')
    New-Item -ItemType Directory -Path $tempRoot | Out-Null

    $inputStream = [System.IO.File]::Open($templatePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $outputStream = [System.IO.File]::Create($templateCopyPath)
        try {
            $inputStream.CopyTo($outputStream)
        }
        finally {
            $outputStream.Close()
        }
    }
    finally {
        $inputStream.Close()
    }

    [System.IO.Compression.ZipFile]::ExtractToDirectory($templateCopyPath, $tempRoot)

    $body = New-ParagraphXml -Text 'BẢNG MÔ TẢ SƠ ĐỒ TỪ FILE SƠ ĐỒ.DOCX' -Justification 'center' -Bold $true
    $body += New-ParagraphXml -Text 'Tài liệu này tổng hợp các bảng mô tả đã được chuẩn hóa từ bộ sơ đồ trong file sơ đồ.docx. Với sơ đồ use case và sơ đồ cấu trúc, mỗi sơ đồ được mô tả bằng một bảng riêng. Với class diagram và ERD, mỗi lớp hoặc thực thể được trình bày bằng một bảng thuộc tính riêng để thuận tiện chèn vào báo cáo chính.' -Justification 'both'
    $body += New-ParagraphXml -Text 'I. BẢNG MÔ TẢ CÁC SƠ ĐỒ USE CASE VÀ SƠ ĐỒ CẤU TRÚC' -Bold $true

    foreach ($item in $useCaseTables) {
        $body += New-ParagraphXml -Text $item.Title -Bold $true
        $body += New-NarrativeTableXml -Rows $item.Rows
        $body += New-ParagraphXml -Text ''
    }

    $body += New-ParagraphXml -Text 'II. BẢNG MÔ TẢ CLASS DIAGRAM' -Bold $true
    foreach ($item in $classTables) {
        $body += New-ParagraphXml -Text $item.Title -Bold $true
        $body += New-EntityTableXml -Fields $item.Fields
        $body += New-ParagraphXml -Text ''
    }

    $body += New-ParagraphXml -Text 'III. BẢNG MÔ TẢ ERD LOGIC' -Bold $true
    foreach ($item in $erdTables) {
        $body += New-ParagraphXml -Text $item.Title -Bold $true
        $body += New-EntityTableXml -Fields $item.Fields
        $body += New-ParagraphXml -Text ''
    }

    $documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
 xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
 xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
 xmlns:v="urn:schemas-microsoft-com:vml"
 xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
 xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
 xmlns:w10="urn:schemas-microsoft-com:office:word"
 xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
 xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
 xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
 xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
 xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
 xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
 mc:Ignorable="w14 wp14">
  <w:body>
$body
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>
      <w:cols w:space="708"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

    [System.IO.File]::WriteAllText((Join-Path $tempRoot 'word\document.xml'), $documentXml, [System.Text.Encoding]::UTF8)

    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    if (Test-Path $outputPath) { Remove-Item $outputPath -Force }

    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $zipPath)
    Move-Item -LiteralPath $zipPath -Destination $outputPath
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
    Remove-Item -LiteralPath $templateCopyPath -Force

    Write-Output "Created: $outputPath"
}
catch {
    throw
}
