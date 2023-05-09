function IsIterable{
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
        $obj
    )
    # If the object implements IEnumerable, then it is iterable.
    if ($null -eq $obj) {
         return $false 
    }
    return [bool]($obj.GetEnumerator())
}

Export-ModuleMember -Function IsIterable

function GetDuplicates{
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        $inputArr
    )

    Begin {
        $groups = $inputArr | Group-Object
        $duplicates = @{}
    }

    Process {
        foreach($i in $groups) {
            if ($i.Count -gt 1) {
                $duplicates[$i.Name] = $i.Count -1
            }
        }
    }
    
    End {
        return $duplicates
    }
    
}

Export-ModuleMember -Function GetDuplicates

function UniqueHeaders {
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
        [ValidateScript({Test-Path $_}, ErrorMessage = "Input items must be a valid path.")]
        $inputPath,

        [Parameter(Mandatory=$True)]
        [string]
        $delimiter
    )

    Begin {
        $arr = (Get-Content -Path $inputPath -TotalCount 1).Split($delimiter)
        $duplicates = GetDuplicates -inputArr $arr
    }

    Process {
        for($i=$arr.Length-1; $i -ge 0; $i--) {
            if ($duplicates.ContainsKey($arr[$i])) {
                if ($duplicates[$arr[$i]] -eq 0) {
                    continue
                }else{
                    $index = $duplicates[$arr[$i]]
                    $duplicates[$arr[$i]]--
                    $arr[$i] = ($arr[$i], $index) -join "_"
                }
            }
        }
    }
    
    End {
        $headers = $arr -join "$delimiter"
        return $headers
    }

}

Export-ModuleMember -Function UniqueHeaders