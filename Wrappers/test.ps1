function sudo2 {
    param (
        [Parameter(Mandatory=$True, Position=0)]
        [string]
        $program,

        [Parameter(Mandatory=$False, Position=1, ValueFromRemainingArguments=$True)]
        [string[]]
        $args
    )
    
    # joins array to string. Note that '&' is used to send program as background process so it won't close.
    [System.Collections.ArrayList]$arrlist = @("-noexit","-command","& $program")
    if ($args -ne $null) {
        $arrlist += $args
    }
    
    $arglist = $arrlist -join ' '
    start-process pwsh -Verb RunAs -ArgumentList "$arglist"
}

sudo2 winget