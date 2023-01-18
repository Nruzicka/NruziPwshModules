function sudo {
    param (
        [Parameter(Mandatory=$True, Position=0)]
        [string]
        $program,

        [Parameter(Mandatory=$False, Position=1, ValueFromRemainingArguments=$True)]
        [string[]]
        $args
    )
    
    # joins array to string. Note that '&' is used to send program as background process so it won't close.
    $arglist = @("-noexit","-command","& $program")
    if ($args -ne $null) {
        $arglist = $arglist + ($args -join " ")
    }
    start-process pwsh -Verb RunAs -ArgumentList "$arglist"
}

Export-ModuleMember -Function sudo 