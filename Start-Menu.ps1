<#
.SYNOPSIS
    Provides a simple menu of commands that can be executed
.DESCRIPTION
    Provides a simple menu of commands generated from reading a JSON file that can be executed.
    The "command" can consist of anything that can be executed (e.g. PowerShell cmdlets, functions, .exe files, etc.)
    By default, command history is saved in a CSV file and the menu displays the last executed command.
.EXAMPLE
    PS C:\> Start-Menu.ps1 -JsonFile menu.json 
    Reads a JSON file and launches the  menu
.LINK
    https://github.com/adegutis/Start-Menu
#>

[cmdletbinding()]
param(
    $JsonFile = '.\Sample.json', 
    $KeepCsvHistory = $True,
    $CsvFile = '.\ScriptHistory.csv'
)

function Get-MenuHistoryFromCsv {
    Param(
        $CsvFile = '.\ScriptHistory.csv'
    )
    Import-Csv $CsvFile | Sort-Object -Descending -Property LastRun | Out-GridView -Wait
}

$Continue = $True
While ($Continue) {

    # Local CSV History File
    if ((test-path $CsvFile) -eq $false) {
        Write-Verbose "$CsvFile not found. Creating it."
        $CsvData = [pscustomobject] @{
            Name    = 'Menu'
            LastRun = get-date
        }
        $CsvData | Export-Csv $CsvFile -NoTypeInformation
    } else {
        Write-Verbose "Getting the last entry from $CsvFile"
        $CSVData = Import-Csv $CsvFile | Select-Object -last 1
    }

    # Read the content of the JSON file
    $RefreshMenuJson = Get-Content $JsonFile | ConvertFrom-Json

    # Build the Menu
    $Menu = @()
    foreach ($item in $RefreshMenuJson.tasks) {
        if ($item.Include -eq 'True') {
            $Menu += [pscustomobject] @{
                Name              = $item.Name
                LastRun           = $null
                ScriptHistoryName = $item.ScriptHistoryName
                ScriptCommand     = $item.ScriptCommand
                ScriptWaitTime    = $item.ScriptWaitTime
            }
        }
    }

    if ($KeepCsvHistory) {
        Foreach ($MenuItem in $Menu) {
            if ($MenuItem.Name -eq $CsvData.Name) {
                $MenuItem.LastRun = $CsvData.LastRun
            } else {
                $MenuItem.LastRun = $Null
            }
        }
    }

    $SelectedScript = $Menu | 
        Select-Object LastRun, Name, ScriptCommand | 
        Out-GridView -Title "Select a function to run" -OutputMode Single 

    $CsvUpdate = [pscustomobject] @{
        Name    = $SelectedScript.Name
        LastRun = Get-Date
    }

    if ($SelectedScript) {
        $CsvUpdate | Export-Csv $CsvFile -NoTypeInformation -Append
        $Command = "$($SelectedScript.ScriptCommand)"
        Write-Verbose "$Command"
        Invoke-Expression "& $Command"
    } else {
        Write-Host "Cancel Button Pressed or some other unexpected failure occurred.." -ForegroundColor Yellow
        $Continue = $False
    }

} # end While
