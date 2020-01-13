[Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 


# from https://www.lewisroberts.com/2015/01/18/powershell-image-resize-function/
Function ResizeImage() {
    param([String]$ImagePath, [Int]$Quality = 90, [Int]$targetSize, [String]$OutputLocation)

    Add-Type -AssemblyName "System.Drawing"

    $img = [System.Drawing.Image]::FromFile($ImagePath)

    $CanvasWidth = $targetSize
    $CanvasHeight = $targetSize

    #Encoder parameter for image quality
    $ImageEncoder = [System.Drawing.Imaging.Encoder]::Quality
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($ImageEncoder, $Quality)

    # get codec
    $Codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where {$_.MimeType -eq 'image/jpeg'}

    #compute the final ratio to use
    $ratioX = $CanvasWidth / $img.Width;
    $ratioY = $CanvasHeight / $img.Height;

    $ratio = $ratioY
    if ($ratioX -le $ratioY) {
        $ratio = $ratioX
    }

    $newWidth = [int] ($img.Width * $ratio)
    $newHeight = [int] ($img.Height * $ratio)

    $bmpResized = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
    $graph = [System.Drawing.Graphics]::FromImage($bmpResized)
    $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $graph.Clear([System.Drawing.Color]::White)
    $graph.DrawImage($img, 0, 0, $newWidth, $newHeight)

    #save to file
    $bmpResized.Save($OutputLocation, $Codec, $encoderParams)
    $bmpResized.Dispose()
    $img.Dispose()
}

    

# from https://stackoverflow.com/questions/2969321/how-can-i-do-a-screen-capture-in-windows-powershell

function screenshot($path) 
{
    $width = 0;
    $height = 0;
    $workingAreaX = 0;
    $workingAreaY = 0;

    $screen = [System.Windows.Forms.Screen]::AllScreens;

    foreach ($item in $screen)
    {
        if($workingAreaX -gt $item.WorkingArea.X)
        {
            $workingAreaX = $item.WorkingArea.X;
        }

        if($workingAreaY -gt $item.WorkingArea.Y)
        {
            $workingAreaY = $item.WorkingArea.Y;
        }

        $width = $width + $item.Bounds.Width;

        if($item.Bounds.Height -gt $height)
        {
            $height = $item.Bounds.Height;
        }
    }

    $bounds = [Drawing.Rectangle]::FromLTRB($workingAreaX, $workingAreaY, $width, $height); 
    $bmp = New-Object Drawing.Bitmap $width, $height;
    $graphics = [Drawing.Graphics]::FromImage($bmp);

    $graphics.CopyFromScreen($bounds.Location, [Drawing.Point]::Empty, $bounds.size);

    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Jpeg);

    $graphics.Dispose();
    $bmp.Dispose();
}