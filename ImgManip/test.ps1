# Use this to test your functions


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
        return $ModPath
    }

}


function ResizePic2 {
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



function ConvertPicTo2(){
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
        Add-Type -AssemblyName System.Drawing
    }

    Process {
        foreach($Img in $ImgPath){
            $Bitmap = [Drawing.Bitmap]::FromFile((Resolve-Path -Path $Img))
            $DestPath = CopyPath -Path $Img -Tag '_new' -NewExt $ImgType -Destination $Destination
            $Bitmap.Save($DestPath, $ImgType)
            $Bitmap.Dispose()
        }
    }

    End {}
}

ConvertPicTo2 -ImgType png -ImgPath .\testpics\1667229149710644.jpg -Destination .\testpics