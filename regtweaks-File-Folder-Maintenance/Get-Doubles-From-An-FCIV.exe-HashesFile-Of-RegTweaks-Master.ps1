<#

.SYNOPSIS
List, delete, replace duplicate files from regtweak-master Github project with hardlinks.

.DESCRIPTION
List, delete, replace duplicate files from regtweak-master Github project with hardlinks using a TabDelimited HashesFile created from result of Fciv.exe -r "regtweaks-master"

.EXAMPLE
./Get-Doubles-From-An-FCIV.exe-HashesFile-Of-regtweaks-Master.ps1 "regtweaks-master-Hashes-Using-FCIV.exe.txt"

.FUNCTIONALITY
Conserve harddrive space and avoid code sprawl.

.NOTES
Requires Microsoft's File Checksum Integrity Verifier Fciv.exe

.LINK
The Github project is located at https://github.com/CHEF-KOCH/regtweaks

#>

# Author              : Noshad Chaudhry
# DTG                 : 20171208
# Version             : 1.0
# Related             : Get-Doubles-From-An-FCIV.exe-HashesFile.ps1
# Comparison          : Comment Me to make me understandable.
# Limitations         : The Temp Batch Script created by this script is subject to limitations of Windows Batch.
# Improvement         : 
#                       1. Detection of hardlinks so as not to delete/recreate the same files on each run.
#                       2. Make the script broader/all encompassing and create the FCIV.exe hashes file thru script.
#                       3. Adhoc way to manage DoublesManagement by adding date, YYYYMMDD, to Files/Temp Scripts.
#                          The script is written in such a way for the user quicly add this to the scrip by him[her]self.
#                       4. Generally better PowerShell and simple error checking.
#                          a. Better PowerShell Try,Catch,Finally or Begin,Process,End block. Functions.
#                             Check if command available based on PowerShell version.
#                          b. Debug/Troubleshooting: _Main-Worker-Procedure 1 is finnicky.
#                                                   When I add IF test path the whole script fails.
#                                                   BUT the script works so this note is just for potential debugging.
# Version History     : 20171208 version 1.0
# todo                : 
#                       1. Regular Expression to check FileIn
# Likely              : 2. Detection of hardlinks so as not to delete/recreate the same files on each run.
#                       Make the TempScripts prompt the user for execution, as they could be clicked on by accident.
#                       Process Command-Line-Arguments $Quiet,$Testing,$DeleteAll.
# Maybe               : None.
#                       3. Make the script broader/all encompassing and create the FCIV.exe hashes file thru script.
# Unlikely            : 4. Add dates to the TempScripts for adhoc tracking of File/Folder Operations.

#SOURCE               : Download Microsoft File Checksum Integrity Verifier from Official Microsoft Dow https://www.microsoft.com/en-us/download/details.aspx?id=11533
#SOURCE               : How do I get the directory of the PowerShell script I execute? [duplicate]      https://stackoverflow.com/questions/17461237/how-do-i-get-the-directory-of-the-powershell-script-i-execute
#SOURCE               : What's the best way to determine the location of the current PowerShell script? https://stackoverflow.com/questions/5466329/whats-the-best-way-to-determine-the-location-of-the-current-powershell-script
#SOURCE               : PowerShell scripting Get-Help about_Comment_Based_Help

# Notes               : See above.

param (
    #Too complex. [cmdletbinding(SupportsShouldProcess=$True)]
    [Parameter(Mandatory=$False)]
    #No default here to allow a few options for relation of ThisScript to the files.
    [String]$GDWFTabDelimFCIVHashedFile,
    [Switch]$Quiet,
    [Switch]$Testing,
    [Switch]$DeleteAll
    )

#ReSet-ENVs                             - Not necessary in PowerShell. Here for clarity.
$GDWFUserDir                        = ""
$GDWFPushedRegTweaksDirBln          = ""

#Checks on FileIn.
$GDWFFileInCorrectDelimFormatLinesC = ""

#Set-ENVs-General-Scripting-File/Folder - Refer to Scripts directory.
IF ($PSScriptRoot)     { $GDWFScriptDir = "$PSScriptRoot"                                                        }
IF (!($GDWFScriptDir)) { $GDWFScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) }

#Set-ENVs-General-Scripting-File/Folder - Name Files/TempScripts after DTG.
$GDWFTempFilesPath                   = "$GDWFScriptDir"
$GDWFTempFilesPath                   = "$ENV:Temp"
$YYYYMMDD                            = "20171208"

#ArgCheck
IF (!($GDWFTabDelimFCIVHashedFile)) { $GDWFTabDelimFCIVHashedFile = "$GDWFScriptDir\regtweaks-master-Hashes-Using-FCIV.exe-TabDelimited-Sorted.txt" }

#Set-ENVs Folder                        - If ThisScript is not in the regtweaks-master folder.
IF (Test-Path "$GDWFScriptDir\regtweaks"           -PathType Container) { $GDWFRegTweaksDir    = "$GDWFScriptDir\regtweaks"           }
IF (Test-Path "$GDWFScriptDir\regtweaks-master"    -PathType Container) { $GDWFRegTweaksDir    = "$GDWFScriptDir\regtweaks-master"    }
IF (Test-Path "$GDWFScriptDir\..\regtweaks"        -PathType Container) { $GDWFRegTweaksDir    = "$GDWFScriptDir\..\regtweaks"        }
IF (Test-Path "$GDWFScriptDir\..\regtweaks-master" -PathType Container) { $GDWFRegTweaksDir    = "$GDWFScriptDir\..\regtweaks-master" }

#Set-ENVs-TempFiles
#TempFiles in UserTempFldr/Disposable for sure.
$GDWFTabDelimFCIVHashedFileCopy    = "$ENV:Temp\GDWFTabDelimFCIVHashedFileCopy.txt"
$GDWFTmpTmpDblsDelimFile           = "$GDWFTempFilesPath\GDWFTmpTmpDblsDelimFile.txt"
$GDWFTempDblsDelimFile             = "$GDWFTempFilesPath\GDWFTempDblsDelimFile.txt"

#TempFiles/Benefit from being permanent in Scripts Directory.
$GDWFTempDblsDelimFileDel          = "$GDWFTempFilesPath\GDWFTempFileDel.ps1"
$GDWFTempDblsDelimFileDelUndo      = "$GDWFTempFilesPath\GDWFTempFileDelUndo.ps1"
$GDWFTempDblsDelimFileHL           = "$GDWFTempFilesPath\GDWFTempFileHL.bat"

#TempFiles in UserTempFldr/Disposable for sure.
IF (Test-Path "$GDWFTempDblsDelimFile")        { RI "$GDWFTempDblsDelimFile"        }
IF (Test-Path "$GDWFTmpTmpDblsDelimFile")      { RI "$GDWFTmpTmpDblsDelimFile"      }

#TempFiles/Benefit from being permanent in Scripts Directory.
IF (Test-Path "$GDWFTempDblsDelimFileDel")     { RI "$GDWFTempDblsDelimFileDel"     }
IF (Test-Path "$GDWFTempDblsDelimFileDelUndo") { RI "$GDWFTempDblsDelimFileDelUndo" }
IF (Test-Path "$GDWFTempDblsDelimFileHL")      { RI "$GDWFTempDblsDelimFileHL"      }

#Does nothing unless TempScripts are in script directory.
IF ($DeleteAll)                                                { Return                                                                                  }

#_Main
IF (!($GDWFTabDelimFCIVHashedFile))                            { Echo "Script Error. Variable GDWFTabDelimFCIVHashedFile is undefined." ; Pause ; Return }
IF (!(Test-Path "$GDWFTabDelimFCIVHashedFile" -PathType Leaf)) { Echo "Script Error. File     GDWFTabDelimFCIVHashedFile doesnt exist." ; Pause ; Return }
IF (!($GDWFRegTweaksDir))                                      { Echo "Script Error. Variable GDWFRegTweaksDir           is undefined." ; Pause ; Return }

#Functions
Function Get-FileFilesCount-ForCD-Recursively {
    $GFFileCTempCount = (GCI -File -Recurse).FullName | Measure-Object | Select-Object Count
    $GFFileCTempCount = ($GFFileCTempCount).Count

    #PowerShell auto assigns zero, but still just in case.
    IF (!($GFFileCTempCount)) { $GFFileCTempCount = "0" }
    $GFFileCTempCount
    }

#File/Folder Location/CurrentDirectory
$GDWFUserDir = (Get-Item -Path ".\" -Verbose).FullName
IF ("$GDWFUserDir" -ne "$GDWFRegTweaksDir") { $GDWFPushedRegTweaksDirBln = "T" ; SL $GDWFRegTweaksDir }

#Checks on FileIn.
#$GDWFFileInCorrectDelimFormatLinesC = GC "$GDWFTabDelimFCIVHashedFile" | Select-String -Pattern "^[0-9a-f]*`t[a-z]:\\[a-z0-9\-_\\`~!@#\$\%^&\*()+=\[\]{}'';,\.]*").Matches.Count

#Copy FileIn ensuring only lines with FCIV Hashes	FileNameFQP is processed.
GC "$GDWFTabDelimFCIVHashedFile" | Select-String -Pattern "[a-z]:" | Out-File -Encoding ASCII "$GDWFTabDelimFCIVHashedFileCopy"

#_Main-DisplayCodeGist
IF (!($Quiet)) {
    Echo ""
    Echo "CodeGist    : List, delete, replace duplicate files from regtweak-master Github project"
    Echo "              create 3 TempScripts to action upon them"
    Echo "              do so in a user prompted and a DebugInformative manner"
    Echo "              1. delete double, 2. replace with Windows HardLinks,"
    Echo "              3. Undo and provide an Undo capability."
    Echo "              Display files that might provide problems for the Batch Create HardLinks TempScript"
    Echo "              Gather FileFiles count before delete, after delete, and after creating hardlinks."
    Echo "              Display FileStats and remind user of importance of the UndoScript."

    Echo ""
    Echo "TempFilesDir: $GDWFTempFilesPath"
    Echo "UndoScript  : $GDWFTempDblsDelimFileDelUndo"

    Echo ""
    Pause
    }

#_Main-Worker-Procedure 1. Get the doubles.
IF (!(Test-Path "$GDWFTmpTmpDblsDelimFile")) {
    (GC "$GDWFTabDelimFCIVHashedFileCopy") | % {
    $CurrHash    = ("$_").Split("`t")[0]
    $CurrFileFQP = ("$_").Split("`t")[1]
    $CurrFileFNX = ("$CurrFileFQP").Split("\")[-1]
    $CurrLine    = "$_"

    IF ("$PrevHash" -eq "$CurrHash") {
        IF ("$CurrFileFNX" -ne "$PrevFileFNX") { Echo "$PrevLine`t$CurrLine" | Out-File -Append -Encoding ASCII "$GDWFTempDblsDelimFile"} }

    $PrevHash    = ("$_").Split("`t")[0]
    $PrevFileFQP = ("$_").Split("`t")[1]
    $PrevFileFNX = ("$PrevFileFQP").Split("\")[-1]
    $PrevLine    = "$_"
    }
}

#Remove unwanted charachters for unchecked null values above.
IF (Test-Path "$GDWFTmpTmpDblsDelimFile" -PathType Leaf) { GC "$GDWFTmpTmpDblsDelimFile" | Select-String -Pattern "[a-z]:" | Out-File -Encoding ASCII "$GDWFTempDblsDelimFile" }

#_Main-Worker-Procedure 2. Create Temp Scripts to operate on doubles, in a manner in which File/Folder OPs can be undone.
IF (Test-Path "$GDWFTempDblsDelimFile" -PathType Leaf) {
(GC "$GDWFTempDblsDelimFile") | % {
    $CurrSrcTgt = ("$_").Split("`t")[1]
    $CurrDest   = ("$_").Split("`t")[3]

    Echo "RI ""$CurrDest"""                        | Out-File -Append -Encoding ASCII "$GDWFTempDblsDelimFileDel"
    Echo "MKLink /H ""$CurrDest"" ""$CurrSrcTgt""" | Out-File -Append -Encoding ASCII "$GDWFTempDblsDelimFileHL"
    Echo "Copy ""$CurrSrcTgt"" ""$CurrDest"""      | Out-File -Append -Encoding ASCII "$GDWFTempDblsDelimFileDelUndo"

    $CurrSrcTgt = ""
    $CurrDest   = ""
    }
}

#Windows Batch Scripting Problem Tokens.
IF (Test-Path "$GDWFTempDblsDelimFileHL")      {
    Echo ""
    Echo "Displaying files that might provide problems for the Batch Create HardLinks TempScript."
    (GC "$GDWFTempDblsDelimFileHL") | Select-String -Pattern "[\^&()\|]"

    Echo ""
    PAUSE
    }

IF ($Testing) {
    #View/DoubleCheck/Analyze the results in a TextEditor.
    IF (Test-Path "$GDWFTempDblsDelimFile")        { & NotePad "$GDWFTempDblsDelimFile"        }
    IF (Test-Path "$GDWFTempDblsDelimFileDel")     { & NotePad "$GDWFTempDblsDelimFileDel"     }
    IF (Test-Path "$GDWFTempDblsDelimFileDelUndo") { & NotePad "$GDWFTempDblsDelimFileDelUndo" }
    IF (Test-Path "$GDWFTempDblsDelimFileHL")      { & NotePad "$GDWFTempDblsDelimFileHL"      }
    }

#FileStats-Initial
IF (Test-Path "$GDWFTempDblsDelimFile" -PathType Leaf) { $GDWFFilesCBefore = Get-FileFilesCount-ForCD-Recursively }
IF (Test-Path "$GDWFTempDblsDelimFile" -PathType Leaf) { $GDWFDblFilesC = (GC "$GDWFTempDblsDelimFile").Count     }

#Prompt user to call TempScript to delete files.
$Wait = ""
IF ( (Test-Path "$GDWFTempDblsDelimFileDel") -AND (!($Quiet)) ) {
    Echo ""
    Echo "CodeGist    : Call TempScript, PowerShell kind, to delete the doubles."
    Echo "EXECUTING   : & $GDWFTempDblsDelimFileDel"

    Echo ""
    $Wait = Read-Host "Hit ENTER to EXECUTE. S[kip] N[o] to skip or Y[es] to execute."
    }
IF ($Wait -eq "S") { $Wait =  "No" }
IF ($Wait -eq "N") { $Wait =  "No" }
IF ($Wait -eq "Q") { $Wait =  "No" }

IF ( (Test-Path "$GDWFTempDblsDelimFileDel") -AND ($Wait -ne "No") ) { & "$GDWFTempDblsDelimFileDel" }

#FileStats-Second
$GDWFFilesCAfter = Get-FileFilesCount-ForCD-Recursively

#Prompt user to call TempScript to create hardLinks with MKLink.exe.
$Wait = ""
IF ( (Test-Path "$GDWFTempDblsDelimFileDel") -AND (!($Quiet)) ) {
    Echo ""
    Echo "CodeGist     : Call TempScript, Batch kind, to create hardLinks with MKLink.exe."
    Echo "EXECUTING    : & $GDWFTempDblsDelimFileHL"

    Echo ""
    $Wait = Read-Host "Hit ENTER to EXECUTE. S[kip] N[o] to skip or Y[es] to execute."
    }
IF ($Wait -eq "S") { $Wait =  "No" }
IF ($Wait -eq "N") { $Wait =  "No" }
IF ($Wait -eq "Q") { $Wait =  "No" }

IF ( (Test-Path "$GDWFTempDblsDelimFileHL") -AND ($Wait -ne "No") ) { & "$GDWFTempDblsDelimFileHL" }
#CMD /C "Ping 127.0.0.1 -n 3 >Nul"

#FileStats-Third
$GDWFFilesCNow = Get-FileFilesCount-ForCD-Recursively

IF (!($Quiet)) {
    Echo ""
    Echo "FileFilesCBefore : $GDWFFilesCBefore"
    Echo "DblFileFilesC    : $GDWFDblFilesC"
    Echo "FileFilesCAfter  : $GDWFFilesCAfter"
    Echo "FileFilesCNow    : $GDWFFilesCNow"

    Echo ""
    Echo "TempDeleteScript : Executed         $GDWFTempDblsDelimFileDel"
    Echo "TempHardLnkScript: Executed         $GDWFTempDblsDelimFileHL"
    Echo "TempDelUndoScript: Ready for use    $GDWFTempDblsDelimFileDelUndo"
    Echo "                   Save this.                                    "
    }

IF ("$GDWFPushedRegTweaksDirBln" -eq "T")          { SL "$GDWFUserDir"                    }

#TempFiles in UserTempFldr/Disposable for sure.
IF (!($Testing)) {
    IF (Test-Path "$GDWFTempDblsDelimFile")        { RI "$GDWFTempDblsDelimFile"          }
    IF (Test-Path "$GDWFTmpTmpDblsDelimFile")      { RI "$GDWFTmpTmpDblsDelimFile"        }
    }

#TempFiles/Benefit from being permanent in Scripts Directory.
#IF (Test-Path "$GDWFTempDblsDelimFileDel")     { RI "$GDWFTempDblsDelimFileDel"     }
#IF (Test-Path "$GDWFTempDblsDelimFileDelUndo") { RI "$GDWFTempDblsDelimFileDelUndo" }
#IF (Test-Path "$GDWFTempDblsDelimFileHL")      { RI "$GDWFTempDblsDelimFileHL"      }

