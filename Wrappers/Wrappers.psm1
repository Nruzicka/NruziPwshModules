function head {
    param (
        [Parameter(Mandatory=$True)]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf}, ErrorMessage = "Input file must be a valid file path")]
        [string]$inputFile,

        [Parameter(Mandatory=$False)]
        [int]$lines = 10
    )

    Get-Content -Path $inputFile | Select-Object -First $lines
}

Export-ModuleMember -Function head




# function sudo {
#     # Deprecated - Windows has implemented their own sudo 
#     param (
#         [Parameter(Mandatory=$True, Position=0)]
#         [string]
#         $program,

#         [Parameter(Mandatory=$False, Position=1, ValueFromRemainingArguments=$True)]
#         [string[]]
#         $args
#     )
    
#     # joins array to string. Note that '&' is used to send program as background process so it won't close.
#     [System.Collections.ArrayList]$arrlist = @("-noexit","-command","& $program")
#     if ($args -ne $null) {
#         $arrlist += $args
#     }
    
#     $arglist = $arrlist -join ' '
#     start-process pwsh -Verb RunAs -ArgumentList "$arglist"
# }

# Export-ModuleMember -Function sudo 
