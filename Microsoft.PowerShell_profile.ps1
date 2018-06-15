# --- Set Screen
# Transparent background - http://richhewlett.com/2011/03/12/windows-powershell-console-fun/
# - disabled by default - glass.ps1
$HOST.UI.RawUI.BackgroundColor  = "Black"
$HOST.UI.RawUI.ForegroundColor  = "Green"
Clear-Host

# --- Set Prompt
function Global:prompt {
	$width = ($Host.UI.RawUI.WindowSize.Width - 2 - $(Get-Location).ToString().Length)
	$hr = New-Object System.String @('.',$width)
	"$(Get-Location) $hr`nPS >"
    }


# --- Set Alias'
Set-Alias em emacs.lnk

# --- Set constants
$MaximumHistoryCount = 200    
$historyPath = Join-Path (split-path $profile) history.clixml

# --- History - http://blog.joonro.net/en/2013/12/20/persistent_history_and_history_search_with_arrow_keys_in_powershell.html
# --- Load history if history file exists
if (Test-path $historyPath)
    { Import-CliXml $historyPath | Add-History }

# --- Save history on exit, remove duplicates
Register-EngineEvent PowerShell.Exiting {
    Get-History -Count $MaximumHistoryCount | Group CommandLine |
    Foreach {$_.Group[0]} | Export-CliXml $historyPath
    } -SupportEvent

# --- hg function to search history
function hg($arg) {
    Get-History -c $MaximumHistoryCount | out-string -stream |
    select-string $arg
    }

# --- Strict debugging
Set-PSDebug -Strict

# --- disk usage function (http://stackoverflow.com/questions/138144/whats-in-your-powershell-profile-ps1file)
function df {
    $colItems = Get-wmiObject -class "Win32_LogicalDisk" -namespace "root\CIMV2" `
    -computername localhost

    foreach ($objItem in $colItems) {
    	write $objItem.DeviceID $objItem.Description $objItem.FileSystem `
    		($objItem.Size / 1GB).ToString("f3") ($objItem.FreeSpace / 1GB).ToString("f3")

        }
    }

# --- Launch Explorer window in current folder
function w {
    explorer .
}


# --- Create a function to turn glass transparent background on and off
function GlassOn
{
    glass.ps1

    $host.ui.RawUI.BackgroundColor = "black"
    $host.ui.rawui.foregroundcolor = "white"

}
 
function GlassOff
{
    glass.ps1 -disable  

    $HOST.UI.RawUI.BackgroundColor  = "Black"
    $HOST.UI.RawUI.ForegroundColor  = "Green"
  
}



# --- Create a function for grep (http://www.out-web.net/?p=757)
function grep (
    $File = $(throw "Empty value for the File parameter."),
    $Pattern = $(throw "Empty value for the Pattern parameter."),
    [switch]$Recurse
    ) {
        if ($Recurse) {
            $Files = @(Get-ChildItem $File -Recurse)
        } else {
            $Files = @(Get-ChildItem $File)
        }
        if ($Files.Count -eq 0) {
            Write-Host "File(s) not found - $File"; return $null
        }
        $Results = $Files | Select-String -Pattern $Pattern
        if (!$Results) {
            Write-Host "No matches found in $File"; return $null
        }
        $Results | Format-List FileName,LineNumber,Line
    }

# --- Create an alias for Tail command (http://www.jonathanmedd.net/2014/02/powershell-tail-equivalent.html)

function Get-ContentTail { 
<# 
    .SYNOPSIS     
    Get the last x lines of a text file 
    .DESCRIPTION 
    Get the last x lines of a text file 
    .PARAMETER Path 
    Path to the text file 
    .PARAMETER Lines 
    Number of lines to retrieve 
    .INPUTS 
    IO.FileInfo 
    System.Int 
    .OUTPUTS 
    System.String 
    .EXAMPLE 
    PS> Get-ContentTail -Path c:\server.log -Lines 10 
    .EXAMPLE 
    PS> Get-ContentTail -Path c:\server.log -Lines 10 -Follow 
#> 
[CmdletBinding()][OutputType('System.String')] 
Param 
    ( 
        [parameter(Mandatory=$true,Position=0)] 
        [ValidateNotNullOrEmpty()] 
        [IO.FileInfo]$Path, 
        [parameter(Mandatory=$true,Position=1)] 
        [ValidateNotNullOrEmpty()] 
        [Int]$Lines, 
        [parameter(Mandatory=$false,Position=2)] 
        [Switch]$Follow 
    ) 
    try { 
        if ($PSBoundParameters.ContainsKey('Follow')){ 
        Get-Content -Path $Path -Tail $Lines -Wait 
        } 
    else { 
        Get-Content -Path $Path -Tail $Lines 
        } 
    } 
    catch [Exception]{ 
        throw "Unable to get the last x lines of a text file....." 
    } 
    } 

New-Alias tail Get-ContentTail

# --- PSReadline for loading history to up arrow/down addor
Import-Module PSReadLine
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Tab -Function Complete