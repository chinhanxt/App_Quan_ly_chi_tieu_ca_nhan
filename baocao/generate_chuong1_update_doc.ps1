$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.IO.Compression.FileSystem

$templatePath = "C:\Users\admin\Documents\VS\app\baocao\bao_cao_6_chuong.docx"
$outputPath = "C:\Users\admin\Documents\VS\app\baocao\cap_nhat_chuong_1_theo_noi_dung_nop.docx"
$tempDir = Join-Path $env:TEMP ("chuong1_update_" + [guid]::NewGuid().ToString("N"))

function New-ParagraphMarkup {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [int]$FontSize = 26,
        [bool]$Bold = $false,
        [ValidateSet('left', 'center')][string]$Align = 'left'
    )

    $escaped = [System.Security.SecurityElement]::Escape($Text)
    $boldMarkup = if ($Bold) { '<w:b/>' } else { '' }

    return @"
<w:p xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:pPr>
    <w:jc w:val="$Align"/>
    <w:spacing w:after="120"/>
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>
      $boldMarkup
      <w:sz w:val="$FontSize"/>
      <w:szCs w:val="$FontSize"/>
      <w:lang w:val="vi-VN"/>
    </w:rPr>
    <w:t>$escaped</w:t>
  </w:r>
</w:p>
"@
}

function New-TableMarkup {
    param(
        [Parameter(Mandatory = $true)][object[]]$Rows
    )

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('<w:tbl xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">')
    [void]$sb.AppendLine('  <w:tblPr>')
    [void]$sb.AppendLine('    <w:tblW w:w="0" w:type="auto"/>')
    [void]$sb.AppendLine('    <w:tblBorders>')
    [void]$sb.AppendLine('      <w:top w:val="single" w:sz="8" w:space="0" w:color="auto"/>')
    [void]$sb.AppendLine('      <w:left w:val="single" w:sz="8" w:space="0" w:color="auto"/>')
    [void]$sb.AppendLine('      <w:bottom w:val="single" w:sz="8" w:space="0" w:color="auto"/>')
    [void]$sb.AppendLine('      <w:right w:val="single" w:sz="8" w:space="0" w:color="auto"/>')
    [void]$sb.AppendLine('      <w:insideH w:val="single" w:sz="6" w:space="0" w:color="auto"/>')
    [void]$sb.AppendLine('      <w:insideV w:val="single" w:sz="6" w:space="0" w:color="auto"/>')
    [void]$sb.AppendLine('    </w:tblBorders>')
    [void]$sb.AppendLine('  </w:tblPr>')
    [void]$sb.AppendLine('  <w:tblGrid>')
    [void]$sb.AppendLine('    <w:gridCol w:w="700"/>')
    [void]$sb.AppendLine('    <w:gridCol w:w="2500"/>')
    [void]$sb.AppendLine('    <w:gridCol w:w="1600"/>')
    [void]$sb.AppendLine('    <w:gridCol w:w="1200"/>')
    [void]$sb.AppendLine('    <w:gridCol w:w="1400"/>')
    [void]$sb.AppendLine('    <w:gridCol w:w="2200"/>')
    [void]$sb.AppendLine('    <w:gridCol w:w="1200"/>')
    [void]$sb.AppendLine('  </w:tblGrid>')

    foreach ($row in $Rows) {
        [void]$sb.AppendLine('  <w:tr>')
        foreach ($cell in $row) {
            $text = [System.Security.SecurityElement]::Escape([string]$cell.Text)
            $boldMarkup = if ($cell.Bold) { '<w:b/>' } else { '' }
            [void]$sb.AppendLine('    <w:tc>')
            [void]$sb.AppendLine('      <w:tcPr><w:tcW w:w="0" w:type="auto"/></w:tcPr>')
            [void]$sb.AppendLine('      <w:p>')
            [void]$sb.AppendLine('        <w:pPr><w:spacing w:after="60"/></w:pPr>')
            [void]$sb.AppendLine('        <w:r>')
            [void]$sb.AppendLine('          <w:rPr>')
            [void]$sb.AppendLine('            <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>')
            if ($boldMarkup) { [void]$sb.AppendLine("            $boldMarkup") }
            [void]$sb.AppendLine('            <w:sz w:val="24"/>')
            [void]$sb.AppendLine('            <w:szCs w:val="24"/>')
            [void]$sb.AppendLine('            <w:lang w:val="vi-VN"/>')
            [void]$sb.AppendLine('          </w:rPr>')
            [void]$sb.AppendLine("          <w:t>$text</w:t>")
            [void]$sb.AppendLine('        </w:r>')
            [void]$sb.AppendLine('      </w:p>')
            [void]$sb.AppendLine('    </w:tc>')
        }
        [void]$sb.AppendLine('  </w:tr>')
    }

    [void]$sb.AppendLine('</w:tbl>')
    return $sb.ToString()
}

try {
    if (Test-Path $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $tempDir | Out-Null
    [IO.Compression.ZipFile]::ExtractToDirectory($templatePath, $tempDir)

    $documentPath = Join-Path $tempDir 'word\document.xml'
    [xml]$docXml = Get-Content -LiteralPath $documentPath -Raw
    $body = $docXml.document.body
    $sectPr = $body.sectPr

    while ($body.HasChildNodes) {
        $body.RemoveChild($body.FirstChild) | Out-Null
    }

    $paragraphs = @(
        @{ Text = 'CẬP NHẬT CHƯƠNG 1 THEO FILE "NỘI DUNG NỘP BÁO CÁO"'; FontSize = 32; Bold = $true; Align = 'center' },
        @{ Text = 'Tài liệu này được tách riêng để thay thế nội dung Chương 1 trong báo cáo gốc.'; FontSize = 26; Bold = $false; Align = 'center' },
        @{ Text = 'CHƯƠNG 1. THÔNG TIN NHÓM'; FontSize = 28; Bold = $true; Align = 'left' },
        @{ Text = '1.1. Đề tài nhóm'; FontSize = 26; Bold = $true; Align = 'left' },
        @{ Text = 'Đề tài của nhóm là xây dựng hệ thống quản lý chi tiêu cá nhân hỗ trợ người dùng ghi nhận các khoản thu, chi, theo dõi ngân sách và quan sát tình hình tài chính theo cách trực quan, dễ dùng hơn so với ghi chép thủ công.'; FontSize = 26; Bold = $false; Align = 'left' },
        @{ Text = 'Thông qua đề tài này, nhóm hướng tới một sản phẩm vừa phục vụ nhu cầu thực tế hằng ngày, vừa thể hiện được quá trình phân tích, thiết kế và xây dựng phần mềm theo đúng định hướng của môn học.'; FontSize = 26; Bold = $false; Align = 'left' },
        @{ Text = '1.2. Tên nhóm'; FontSize = 26; Bold = $true; Align = 'left' },
        @{ Text = 'Tên nhóm là Tracker.'; FontSize = 26; Bold = $false; Align = 'left' },
        @{ Text = 'Tên gọi này ngắn gọn, dễ nhớ và phù hợp với tinh thần của đề tài vì nhấn mạnh vào việc theo dõi, cập nhật và kiểm soát liên tục các hoạt động tài chính cá nhân của người dùng.'; FontSize = 26; Bold = $false; Align = 'left' },
        @{ Text = '1.3. Ý nghĩa nhóm'; FontSize = 26; Bold = $true; Align = 'left' },
        @{ Text = 'Tên nhóm thể hiện mục tiêu theo dõi, kiểm soát và cải thiện tình hình tài chính cá nhân một cách chủ động, rõ ràng và liên tục thông qua hệ thống phần mềm mà nhóm xây dựng.'; FontSize = 26; Bold = $false; Align = 'left' },
        @{ Text = 'Bên cạnh đó, ý nghĩa của tên nhóm cũng phản ánh tinh thần làm việc có định hướng, biết quan sát tiến độ, bám sát mục tiêu và cùng nhau hoàn thiện sản phẩm theo từng giai đoạn.'; FontSize = 26; Bold = $false; Align = 'left' },
        @{ Text = '1.4. Danh sách thành viên nhóm gồm (STT, họ tên, MSSV, lớp, phone, email, trưởng nhóm)'; FontSize = 26; Bold = $true; Align = 'left' },
        @{ Text = 'Bảng dưới đây tổng hợp thông tin cơ bản của các thành viên trong nhóm theo đúng cấu trúc yêu cầu nộp báo cáo. Các trường chưa có dữ liệu chi tiết có thể bổ sung thêm sau nếu cần.'; FontSize = 24; Bold = $false; Align = 'left' }
    )

    foreach ($item in $paragraphs) {
        $fragment = $docXml.CreateDocumentFragment()
        $fragment.InnerXml = New-ParagraphMarkup -Text $item.Text -FontSize $item.FontSize -Bold $item.Bold -Align $item.Align
        $body.AppendChild($fragment.FirstChild) | Out-Null
    }

    $tableRows = @(
        @(
            @{ Text = 'STT'; Bold = $true },
            @{ Text = 'Họ và tên'; Bold = $true },
            @{ Text = 'MSSV'; Bold = $true },
            @{ Text = 'Lớp'; Bold = $true },
            @{ Text = 'Phone'; Bold = $true },
            @{ Text = 'Email'; Bold = $true },
            @{ Text = 'Trưởng nhóm'; Bold = $true }
        ),
        @(
            @{ Text = '1'; Bold = $false },
            @{ Text = 'BÙI NGUYỄN CÔNG NGHIỆP'; Bold = $false },
            @{ Text = '2380601461'; Bold = $false },
            @{ Text = '23DTHC3'; Bold = $false },
            @{ Text = 'Chưa bổ sung'; Bold = $false },
            @{ Text = 'Chưa bổ sung'; Bold = $false },
            @{ Text = ''; Bold = $false }
        ),
        @(
            @{ Text = '2'; Bold = $false },
            @{ Text = 'NGUYỄN CHÍ NHÂN'; Bold = $false },
            @{ Text = '2380601523'; Bold = $false },
            @{ Text = '23DTHC3'; Bold = $false },
            @{ Text = 'Chưa bổ sung'; Bold = $false },
            @{ Text = 'Chưa bổ sung'; Bold = $false },
            @{ Text = ''; Bold = $false }
        ),
        @(
            @{ Text = '3'; Bold = $false },
            @{ Text = 'LƯU VĂN LƯƠNG'; Bold = $false },
            @{ Text = '2380601304'; Bold = $false },
            @{ Text = '23DTHC3'; Bold = $false },
            @{ Text = 'Chưa bổ sung'; Bold = $false },
            @{ Text = 'Chưa bổ sung'; Bold = $false },
            @{ Text = ''; Bold = $false }
        ),
        @(
            @{ Text = '4'; Bold = $false },
            @{ Text = 'HOÀNG NHẬT QUÂN'; Bold = $false },
            @{ Text = '2380601822'; Bold = $false },
            @{ Text = '23DTHC3'; Bold = $false },
            @{ Text = 'Chưa bổ sung'; Bold = $false },
            @{ Text = 'Chưa bổ sung'; Bold = $false },
            @{ Text = ''; Bold = $false }
        )
    )

    $tableFragment = $docXml.CreateDocumentFragment()
    $tableFragment.InnerXml = New-TableMarkup -Rows $tableRows
    $body.AppendChild($tableFragment.FirstChild) | Out-Null

    $body.AppendChild($sectPr) | Out-Null
    $docXml.Save($documentPath)

    $finalOutputPath = $outputPath
    if (Test-Path $finalOutputPath) {
        try {
            Remove-Item -LiteralPath $finalOutputPath -Force
        }
        catch {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($outputPath)
            $dirName = [System.IO.Path]::GetDirectoryName($outputPath)
            $ext = [System.IO.Path]::GetExtension($outputPath)
            $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
            $finalOutputPath = Join-Path $dirName ("{0}_{1}{2}" -f $baseName, $timestamp, $ext)
        }
    }

    [IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $finalOutputPath)
    Write-Output $finalOutputPath
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
}
