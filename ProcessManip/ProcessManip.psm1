function ToggleForeground {
    param (
        [Parameter(Mandatory=$True)]
        [string]
        $Pattern,

        [Parameter(Mandatory=$True)]
        [ValidateSet(0, 1)]
        [Int16]
        $Toggle
    )

    Begin{
        $sig = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
        Add-Type -MemberDefinition $sig -Name NativeMethods -Namespace Win32
        $myproc = Get-Process $Pattern | Where-Object {$_.MainWindowHandle -ne 0}
    }

    Process{
        if ($null -eq $myproc) {
            Write-Output "Error: No process window found."
        } elseif ($myproc.GetType().IsArray) {
            Write-Output "Error: Multiple processes with name detected"
            Write-Output $myproc
        } else {
            $hwnd = $myproc.MainWindowHandle
            if ($Toggle -eq 0) {
                [Win32.NativeMethods]::ShowWindowAsync($hwnd, 2)
            }
            else {
                [Win32.NativeMethods]::ShowWindowAsync($hwnd, 4)
            }
        }
    }

}

Export-ModuleMember -Function ToggleForeground


function GetSize{
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$true)]
        [string]
        $path,

        [Parameter(Mandatory=$false)]
        [ValidateSet('KB', 'MB', 'GB', 'TB')]
        [string]
        $measurement
    )
    
    $size = (Get-ChildItem $path -Force -Recurse | Measure-Object -Property Length -Sum).Sum

    switch ($measurement) {
        'KB' {return $($size/1000)}
        'MB' {return $($size/1000000)}
        'GB' {return $($size/1000000000)}
        'TB' {return $($size/1000000000000)}
        Default {return $size}
    }
}

Export-ModuleMember -Function GetSize