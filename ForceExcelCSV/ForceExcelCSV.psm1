function ExcelOpenCSV {
    param (
        [Parameter(Mandatory=$True)]
        [string]$Path,

        [Parameter(Mandatory=$False)]
        [string]$Delim = ","
    )
    $fullPath = (Resolve-Path -Path $Path).Path
    $queryName = "pQuery"
    $connString = 'OLEDB;Provider=Microsoft.Mashup.OleDb.1;Data Source=$Workbook$";Location=pQuery'
    $mCode = "let`n
        Source = Csv.Document(File.Contents(""" + $fullPath + """),[Delimiter=""" + $Delim + """]),`n
        PromHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),`n
        ForceText = Table.TransformColumnTypes(PromHeaders,`n
            List.Transform(Table.ColumnNames(PromHeaders), each{_, type text}))`n
        in`n
            ForceText"
    
    $Excel = New-Object -ComObject excel.application
    $wb = $Excel.Workbooks.Add()
    $ws = $wb.Worksheets.Item(1)
    $query = $wb.Queries.Add($queryName, $mCode)
    $qTable = $ws.QueryTables.Add($connString, $ws.Cells.Item(1,1))
    $qTable.Name = "qTable"
    $qTable.CommandText = "pQuery"
    $qTable.RefreshStyle = 1
    $qTable.Refresh()
    $query.Delete()
    $Excel.Visible=$True

    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($query)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($qTable)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($ws)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wb)
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($Excel)
    Remove-Variable excel
}