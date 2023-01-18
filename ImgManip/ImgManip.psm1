function CopyPath {
    Param(
        [parameter(Mandatory=$True)]
        [string]
        $Path,

        [parameter(Mandatory=$False)]
        [string]
        $Tag = "",

        [parameter(Mandatory=$False)]
        [string]
        $NewExt,

        [parameter(Mandatory=$False)]
        [ValidateScript({Test-Path $_ -PathType Container}, ErrorMessage =  "Destination must be a directory.")]
        [string]
        $Destination
    )

    Begin{
        $sb = [System.Text.StringBuilder]::new((Get-ChildItem -Path $Path).BaseName)
        [void]$sb.Append($Tag)
    }

    Process{
        if($NewExt){
            [void]$sb.AppendJoin(".", ('',$NewExt))
        }else{
            [void]$sb.Append((Get-ChildItem -Path $Path).Extension)
        }
        if($Destination){
            [void]$sb.Insert(0, "\")
            [void]$sb.Insert(0, $Destination) 
        }
    }

    End{
        $ModPath = $sb.ToString()
        $sb.Dispose()
        return $ModPath
    }

}

Export-ModuleMember -Function CopyPath


function GetBitmap {
   param (
     [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$true)]
     [String]$Path 
   )
   
   Add-Type -AssemblyName System.Drawing
   $Image = [System.Drawing.Bitmap]::FromFile((Resolve-Path -Path $Path))   
   return $Image
}
Export-ModuleMember -Function GetBitmap

Function Resize-Image() {
    [CmdLetBinding(
        SupportsShouldProcess=$true, 
        PositionalBinding=$false,
        ConfirmImpact="Medium",
        DefaultParameterSetName="Absolute"
    )]
    Param (
        [Parameter(Mandatory=$True)]
        [ValidateScript({
            $_ | ForEach-Object {
                Test-Path $_
            }
        })][String[]]$ImagePath,
        [Parameter(Mandatory=$False)][Switch]$MaintainRatio,
        [Parameter(Mandatory=$False, ParameterSetName="Absolute")][Int]$Height,
        [Parameter(Mandatory=$False, ParameterSetName="Absolute")][Int]$Width,
        [Parameter(Mandatory=$False, ParameterSetName="Percent")][Double]$Percentage,
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.SmoothingMode]$SmoothingMode = "HighQuality",
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.InterpolationMode]$InterpolationMode = "HighQualityBicubic",
        [Parameter(Mandatory=$False)][System.Drawing.Drawing2D.PixelOffsetMode]$PixelOffsetMode = "HighQuality",
        [Parameter(Mandatory=$False)][String]$NameModifier = "resized"
    )
    Begin {
        If ($Width -and $Height -and $MaintainRatio) {
            Throw "Absolute Width and Height cannot be given with the MaintainRatio parameter."
        }
 
        If (($Width -xor $Height) -and (-not $MaintainRatio)) {
            Throw "MaintainRatio must be set with incomplete size parameters (Missing height or width without MaintainRatio)"
        }
 
        If ($Percentage -and $MaintainRatio) {
            Write-Warning "The MaintainRatio flag while using the Percentage parameter does nothing"
        }
    }
    Process {
        ForEach ($Image in $ImagePath) {
            $Path = (Resolve-Path $Image).Path
            $Dot = $Path.LastIndexOf(".")

            #Add name modifier (OriginalName_{$NameModifier}.jpg)
            $OutputPath = $Path.Substring(0,$Dot) + "_" + $NameModifier + $Path.Substring($Dot,$Path.Length - $Dot)
            
            $OldImage = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Path
            # Grab these for use in calculations below. 
            $OldHeight = $OldImage.Height
            $OldWidth = $OldImage.Width
 
            If ($MaintainRatio) {
                $OldHeight = $OldImage.Height
                $OldWidth = $OldImage.Width
                If ($Height) {
                    $Width = $OldWidth / $OldHeight * $Height
                }
                If ($Width) {
                    $Height = $OldHeight / $OldWidth * $Width
                }
            }
 
            If ($Percentage) {
                $Product = ($Percentage / 100)
                $Height = $OldHeight * $Product
                $Width = $OldWidth * $Product
            }

            $Bitmap = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Width, $Height
            $NewImage = [System.Drawing.Graphics]::FromImage($Bitmap)
             
            #Retrieving the best quality possible
            $NewImage.SmoothingMode = $SmoothingMode
            $NewImage.InterpolationMode = $InterpolationMode
            $NewImage.PixelOffsetMode = $PixelOffsetMode
            $NewImage.DrawImage($OldImage, $(New-Object -TypeName System.Drawing.Rectangle -ArgumentList 0, 0, $Width, $Height))

            If ($PSCmdlet.ShouldProcess("Resized image based on $Path", "save to $OutputPath")) {
                $Bitmap.Save($OutputPath)
            }
            
            $Bitmap.Dispose()
            $NewImage.Dispose()
        }
    }
}

Export-ModuleMember -Function Resize-Image


function ResizePic {
    [CmdLetBinding(
        PositionalBinding = $False
    )]
    param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
        [ValidateScript({$_ | ForEach-Object{Test-Path $_}}, ErrorMessage = "Input items must be a valid path.")]
        [String[]]
        $ImgPath,

        [Parameter(Mandatory=$True)]
        [Int]
        $Width,

        [Parameter(Mandatory=$True)]
        [Int]
        $Height,

        [Parameter(Mandatory = $False)]
        [ValidateScript({Test-Path -Path $_ -PathType Container}, ErrorMessage = "Destination must be a directory.")]
        [String]
        $Destination = (Resolve-Path -Path ".").Path
    )
    
    Begin {
        Add-Type -AssemblyName System.Drawing
    }

    #Note, process blocks are mandatory for piping arrays.
    Process {
        foreach($Img in $ImgPath){
            $DestPath = CopyPath -Path $Img -Tag '_resized' -Destination $Destination
            # Create a new image, then have the Graphics class draw on it based on the old image.
            $OldImg = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Img
            $NewImg = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $Width,$Height
            $NewGraphic = [System.Drawing.Graphics]::FromImage($NewImg)
            $NewGraphic.PixelOffsetMode = "HighQuality"
            $NewGraphic.SmoothingMode = "HighQuality"
            $NewGraphic.InterpolationMode = "HighQualityBicubic"
            $NewGraphic.DrawImage($OldImg,0,0,$Width,$Height)
            $NewImg.Save($DestPath)

            $OldImg.Dispose()
            $NewImg.Dispose()
            $NewGraphic.Dispose()
        }
    }
    
    End{}

}

Export-ModuleMember -Function ResizePic


function ConvertPicTo(){
    param(
        [Parameter(Mandatory=$True)]
        [ValidateSet('png', 'bmp', 'jpeg', 'gif', 'icon')]
        [string]
        $ImgType,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
        [ValidateScript({$_ | ForEach-Object{Test-Path $_}}, ErrorMessage = "Input must be a valid path.")]
        [String[]]
        $ImgPath,

        [Parameter(Mandatory=$False)]
        [ValidateScript({Test-Path $_ -PathType Container}, ErrorMessage =  "Destination must be a directory.")]
        [String]
        $Destination = (Resolve-Path -Path ".").Path
    )

    Begin {
        Add-Type -AssemblyName 'System.Windows.Forms'
    }

    Process {
        foreach($Img in $ImgPath){
            $Bitmap = New-Object -TypeName System.Drawing.Bitmap($Img)
            $DestPath = CopyPath -Path $Img -Tag '_new' -NewExt $ImgType -Destination $Destination
            $Bitmap.Save($DestPath, $ImgType)
            $Bitmap.Dispose()
        }
    }

    End {}
}

Export-ModuleMember -Function ConvertPicTo

   