Start-Process "ms-screenclip:"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Windows.Forms.Clipboard]::Clear()
$maxWait = 30
$waited = 0
$lastClipboardContent = ""

while ($waited -lt $maxWait) {
    Start-Sleep -Milliseconds 500
    $waited += 0.5

    if ([Windows.Forms.Clipboard]::ContainsImage()) {
        $image = [Windows.Forms.Clipboard]::GetImage()
        $newClipboardContent = $image.GetHashCode().ToString()
        if ($newClipboardContent -ne $lastClipboardContent) {
            $lastClipboardContent = $newClipboardContent
            break
        }
    }
}


if (-not [Windows.Forms.Clipboard]::ContainsImage()) {
    Write-Host "No screenshot was taken or the clipboard is empty."
    exit
}

$image = [Windows.Forms.Clipboard]::GetImage()
$aspectRatio = $image.Width / $image.Height

$formTemp = New-Object Windows.Forms.Form
$formTemp.FormBorderStyle = 'SizableToolWindow'
$formTemp.Show()
$frameWidth  = $formTemp.Width  - $formTemp.ClientSize.Width
$frameHeight = $formTemp.Height - $formTemp.ClientSize.Height
$formTemp.Close()

$form = New-Object Windows.Forms.Form
$form.Text = "Pinned Screenshot"
$form.TopMost = $true
$form.FormBorderStyle = 'SizableToolWindow'
$form.BackColor = [System.Drawing.Color]::Black

$maxDim = 500.0
if ($image.Width -gt $maxDim -or $image.Height -gt $maxDim) {
    if ($image.Width -ge $image.Height) {
        $scaledWidth = [math]::Round($maxDim)
        $scaledHeight = [math]::Round($maxDim / $aspectRatio)
    } else {
        $scaledHeight = [math]::Round($maxDim)
        $scaledWidth = [math]::Round($maxDim * $aspectRatio)
    }
} else {
    $scaledWidth = $image.Width
    $scaledHeight = $image.Height
}

$form.Width  = [int]$scaledWidth + $frameWidth
$form.Height = [int]$scaledHeight + $frameHeight
$form.MinimumSize = New-Object System.Drawing.Size(100, 100)

$pictureBox = New-Object Windows.Forms.PictureBox
$pictureBox.Image = $image
$pictureBox.SizeMode = 'StretchImage'
$pictureBox.Dock = 'Fill'
$form.Controls.Add($pictureBox)


$screenWidth = [int][System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width
$screenHeight = [int][System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Height

$formWidth = [int]$form.Width
$formHeight = [int]$form.Height
$form.Location = New-Object System.Drawing.Point(10, 10)

$lastClientSize = $form.ClientSize

$form.Add_Resize({
    $deltaWidth = $form.ClientSize.Width - $lastClientSize.Width
    $deltaHeight = $form.ClientSize.Height - $lastClientSize.Height

    if ([math]::Abs($deltaWidth) -gt [math]::Abs($deltaHeight)) {
        $newWidth = $form.ClientSize.Width
        $newHeight = [math]::Round($newWidth / $aspectRatio)
    }
    else {
        $newHeight = $form.ClientSize.Height
        $newWidth = [math]::Round($newHeight * $aspectRatio)
    }

    $form.Width = [math]::Max($newWidth + $frameWidth, 100 + $frameWidth)
    $form.Height = [math]::Max($newHeight + $frameHeight, 100 + $frameHeight)
    $lastClientSize = $form.ClientSize
})

[Windows.Forms.Application]::EnableVisualStyles()
[Windows.Forms.Application]::Run($form)
