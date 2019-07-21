    ##--------------------------------------------------------------------------
    ##  FUNCTION.......:  Get-Screenshot
    ##  PURPOSE........:  Takes a screenshot and saves it to a file.
    ##  REQUIREMENTS...:  PowerShell 2.0
    ##  NOTES..........:  
    ##--------------------------------------------------------------------------
    Function Get-Screenshot {
        <#
        .SYNOPSIS
         Takes a screenshot and writes it to a file.
        .DESCRIPTION
         The Get-Screenshot Function uses the System.Drawing .NET assembly to 
         take a screenshot, and then writes it to a file.
        .PARAMETER <Path>
         The path where the file will be stored. If a trailing backslash is used
         the operation will fail. See the examples for syntax.
        .PARAMETER <png>
         This optional switch will save the resulting screenshot as a PNG file.
         This is the default setting.
        .PARAMETER <jpeg>
         This optional switch will save the resulting screenshot as a JPEG file.
        .PARAMETER <bmp>
         This optional switch will save the resulting screenshot as a BMP file.
        .PARAMETER <gif>
         This optional switch will save the resulting screenshot as a GIF file.
         session.
        .EXAMPLE
         C:\PS>Get-Screenshot c:\screenshots
         
         This example will create a PNG screenshot in the directory 
         "C:\screenshots".
         
        .EXAMPLE
         C:\PS>Get-Screenshot c:\screenshot -jpeg
        
         This example will create a JPEG screenshot in the directory 
         "C:\screenshots".
        
        .EXAMPLE
         C:\PS>Get-Screenshot c:\screenshot -verbose
         
         This example will create a PNG screenshot in the directory 
         "C:\screenshots". This usage will also write verbose output to the 
         comsole (inlucding the full filepath and name of the resulting file).
         
        .NOTES
         NAME......:  Get-Screenshot
         AUTHOR....:  Joe Glessner
         LAST EDIT.:  12MAY11
         CREATED...:  11APR11
        .LINK
         http://joeit.wordpress.com/
        #>
        [CmdletBinding()]             
            Param (                        
                    [Parameter(Mandatory=$True, 
                        Position=0,                           
                        ValueFromPipeline=$false,             
                        ValueFromPipelineByPropertyName=$false)]  
                    [String]$Path,
                    [Switch]$jpeg,
                    [Switch]$bmp,
                    [Switch]$gif
                )#End Param
        $asm0 = [System.Reflection.Assembly]::LoadWithPartialName(`
            "System.Drawing")
        Write-Verbose "Assembly loaded: $asm0"
        $asm1 = [System.Reflection.Assembly]::LoadWithPartialName(`
            "System.Windows.Forms")
        Write-Verbose "Assembly Loaded: $asm1"
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $Bitmap = new-object System.Drawing.Bitmap $screen.width,$screen.height
        $Size = New-object System.Drawing.Size $screen.width,$screen.height
        $FromImage = [System.Drawing.Graphics]::FromImage($Bitmap)
        $FromImage.copyfromscreen(0,0,0,0, $Size,
            ([System.Drawing.CopyPixelOperation]::SourceCopy))
        $Timestamp = get-date -uformat "%Y_%m_%d_@_%H%M_%S"
        If ([IO.Directory]::Exists($Path)) { 
            Write-Verbose "Directory $Path already exists." 
        }#END: If ([IO.Directory]::Exists($Path))
        Else { 
            [IO.Directory]::CreateDirectory($Path) | Out-Null
            Write-Verbose "Folder $Path does not exist, creating..."
        }#END: Else
        If ($jpeg) {
            $FileName = "\$($Timestamp)_screenshot.jpeg"
            $Target = $Path + $FileName
            $Bitmap.Save("$Target",
                ([system.drawing.imaging.imageformat]::Jpeg));
        }#END: If ($jpeg)
        ElseIf ($bmp) {
            $FileName = "\$($Timestamp)_screenshot.bmp"
            $Target = $Path + $FileName
            $Bitmap.Save("$Target",
                ([system.drawing.imaging.imageformat]::Bmp));
        }#END: If ($bmp)
        ElseIf ($gif) {
            $FileName = "\$($Timestamp)_screenshot.gif"
            $Target = $Path + $FileName
            $Bitmap.Save("$Target",
                ([system.drawing.imaging.imageformat]::Gif));
        }
        Else {
            $FileName = "\$($Timestamp)_screenshot.png"
            $Target = $Path + $FileName
            $Bitmap.Save("$Target",
                ([system.drawing.imaging.imageformat]::Png));
        }#END: Else
        Write-Verbose "File saved to: $target"
    }#END: Function Get-Screenshot