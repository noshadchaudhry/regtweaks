<#

.SYNOPSIS
List, delete, replace duplicate files from regtweak-master Github project with hardlinks.

.DESCRIPTION
List, delete, replace duplicate files from regtweak-master Github project with hardlinks using a TabDelimited HashesFile created from result of Fciv.exe -r "regtweaks-master"
Create separate FilesLists for doubles with same FileNames and another based on hashes only.
These lists can help manage code sprawl.

.EXAMPLE
Mandatory Arguments    None.
Optional Arguments     GeneralScripting       -Quiet, -Testing, -DeleteAll
                       ThisScriptScripting    -ScriptDir -FNX

./Get-Doubles-From-An-FCIV.exe-HashesFile-Of-regtweaks-Master.ps1                                              Use already created FCIV.exe hashes file in scripts directory.
./Get-Doubles-From-An-FCIV.exe-HashesFile-Of-regtweaks-Master.ps1 "regtweaks-master-Hashes-Using-FCIV.exe.txt" Pass a file to the script.
./Get-Doubles-From-An-FCIV.exe-HashesFile-Of-regtweaks-Master.ps1 -ScriptDir                                   Create TempScripts in the scripts directory.

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
# Limitations         : The TempBatchScript created by this script is subject to limitations of Windows Batch.
# Improvement         : 
#                       1. Detection of hardlinks so as not to delete/recreate the same files on each run.
#                       2. Make the script broader/all encompassing and create the FCIV.exe hashes file thru script.self.
#                       3. Generally better PowerShell and simple error checking.
#                          a. Better PowerShell Try,Catch,Finally or Begin,Process,End block. Functions.
#                             Check if command available based on PowerShell version.
#                          b. Debug/Troubleshooting: _Main-Worker-Procedure 1 is finnicky.
#                                                   When I add IF test path the whole script fails.
#                                                   BUT the script works so this note is just for potential debugging.
# Version History     : 20171208 version 1.0
# todo                : 
#                       1. Regular Expression that captures the whole line to check FileIn.
# Likely              : 2. Detection of hardlinks so as not to delete/recreate the same files on each run.
#                       Make the TempScripts prompt the user for execution, as they could be clicked on by accident.
# Maybe               : None.
#                       2. Make the script broader/all encompassing and create the FCIV.exe hashes file thru script.
# Unlikely            : 3. Better PowerShell as reached my PowerShell max knowledge.

#SOURCE               : Download Microsoft File Checksum Integrity Verifier from Official Microsoft Dow https://www.microsoft.com/en-us/download/details.aspx?id=11533
#SOURCE               : How do I get the directory of the PowerShell script I execute? [duplicate]      https://stackoverflow.com/questions/17461237/how-do-i-get-the-directory-of-the-powershell-script-i-execute
#SOURCE               : What's the best way to determine the location of the current PowerShell script? https://stackoverflow.com/questions/5466329/whats-the-best-way-to-determine-the-location-of-the-current-powershell-script
#SOURCE               : PowerShell scripting Get-Help                                                   about_Comment_Based_Help
#SOURCE               : Windows PowerShell Tip_ Formatting Dates and Times.html                         https://technet.microsoft.com/en-us/library/ee692801.aspx
#SOURCE               : PowerShell Scripting _ Microsoft Docs.html                                      https://docs.microsoft.com/en-us/powershell/scripting/powershell-scripting?view=powershell-6
#SOURCE               : Windows Management Framework (Windows PowerShell 2.0, WinRM 2.0, and BITS 4.0). https://support.microsoft.com/en-us/help/968929/windows-management-framework-windows-powershell-2-0--winrm-2-0--and-bi
#SOURCE               : Overview of Cmdlets Available in Windows PowerShell.html                        https://technet.microsoft.com/en-us/library/ff714569.aspx
#SOURCE               : Windows PowerShell 2.0 Tips.html                                                https://technet.microsoft.com/en-us/library/ff630157.aspx

# Notes               : 
#                       Variables/CMDLets/Methods/Features used
#                       $MyInvocation, $PSScriptRoot, Test-Path, Get-Date, Get-Content, Remove-Item,
#                       Get-ChildItem, Measure-Object, Select-Object, Select-String, Sort-Object, Out-File
#                       Set-Location, Read-Host, .Split method, & Call operator, CommentBasedHelp
param (
    #Too complex. [cmdletbinding(SupportsShouldProcess=$True)]
    [Parameter(Mandatory=$False)]
    #No default here to allow a few options for relation of ThisScript to the files.
    [String]$GDWFTabDelimFCIVHashedFile,
    [Switch]$Quiet,
    [Switch]$Testing,
    [Switch]$DeleteAll,
    [Switch]$SameFileNameFNX,
    [Switch]$FileNameFNX,
    [Switch]$FNX,
    [Switch]$ScriptDir
    )

#ReSet-ENVs                             - Not necessary in PowerShell. Here for clarity.
#ArgCheck
#GeneralScriptingOptions
#$Quiet
#$Testing
#$DeleteAll
#$ScriptDir

#ThisScriptScriptingOptions
$OnlySameFileNameFNX                = ""

#_Main
#Set-ENVs-General-Scripting-File/Folder - Refer to Scripts directory.
$GDWFScriptDir                      = ""

#File/Folder Location/CurrentDirectory
$GDWFUserDir                        = ""
$GDWFPushedRegTweaksDirBln          = ""

#Checks on FileIn.
$GDWFFileInCorrectDelimFormatLinesC = ""

#FileStats
$GDWFTabDelimFCIVHashedFileCopyLC   = ""
$GDWFFilesCBefore                   = ""
$GDWFFilesCAfter                    = ""
$GDWFFilesCNow                      = ""
$GDWFDblFilesC                      = ""
$GDWFDblBasedOnHashOnlyFilesC       = ""
$GDWFDblBasedOnHashNFNameFilesC     = ""

#Set-ENVs-TempFiles
#TempFiles in UserTempFldr/Disposable for sure.
$GDWFTabDelimFCIVHashedFileCopy     = ""
$GDWFTmpTmpDblsDelimFile            = ""
$GDWFTempDblsDelimFile              = ""

$GDWFDblsBasedOnHashOnlyDelim       = ""
$GDWFDblsBasedOnHashNFNameDelim     = ""

#TempFiles/Benefit from being permanent in Scripts Directory.
$GDWFTempDblsDelimFileDel           = ""
$GDWFTempDblsDelimFileDelUndo       = ""
$GDWFTempDblsDelimFileHL            = ""

#Set-ENVs-General-Scripting-File/Folder - Refer to Scripts directory.
IF ($PSScriptRoot)     { $GDWFScriptDir = "$PSScriptRoot"                                                        }
IF (!($GDWFScriptDir)) { $GDWFScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition) }

#Set-ENVs-General-Scripting-File/Folder - Name Files/TempScripts after DTG.
IF ($ScriptDir)    { $GDWFTempFilesPath                   = "$GDWFScriptDir" }
IF (!($ScriptDir)) { $GDWFTempFilesPath                   = "$ENV:Temp"      }
$YYYYMMDD                           = (Get-Date -format u).Split("- ")[0,1,2] -Join ""
IF (!($YYYYMMDD))  { $YYYYMMDD                            = "20170101"       }

#ArgCheck
IF (!($GDWFTabDelimFCIVHashedFile)) { $GDWFTabDelimFCIVHashedFile = "$GDWFScriptDir\regtweaks-master-Hashes-Using-FCIV.exe-TabDelimited-Sorted.txt" }

IF ([Switch]$SameFileNameFNX) { [String]$OnlySameFileNameFNX = "$True" }
IF ([Switch]$FileNameFNX)     { [String]$OnlySameFileNameFNX = "$True" }
IF ([Switch]$FNX)             { [String]$OnlySameFileNameFNX = "$True" }

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
$GDWFDblsBasedOnHashOnlyDelim      = "$GDWFTempFilesPath\regtweaks-master-$YYYYMMDD-List-DblsBasedOnHashOnly-TabDelimited.txt"
$GDWFDblsBasedOnHashNFNameDelim    = "$GDWFTempFilesPath\regtweaks-master-$YYYYMMDD-List-DblsBasedOnHash-N-FName-TabDelimited.txt"

$GDWFTempDblsDelimFileDel          = "$GDWFTempFilesPath\regtweaks-master-$YYYYMMDD-Delete-WhatsConsideredDblsTempPowerShellScript.ps1"
$GDWFTempDblsDelimFileDelUndo      = "$GDWFTempFilesPath\regtweaks-master-$YYYYMMDD-Delete-WhatsConsideredDblsTempPowerShellScript-Undo.ps1"
$GDWFTempDblsDelimFileHL           = "$GDWFTempFilesPath\regtweaks-master-$YYYYMMDD-Create-HardLinks-WhatsConsideredDblsTempBatchScript.bat"

#TempFiles in UserTempFldr/Disposable for sure.
IF (Test-Path "$GDWFTempDblsDelimFile")          { RI "$GDWFTempDblsDelimFile"          }
IF (Test-Path "$GDWFTmpTmpDblsDelimFile")        { RI "$GDWFTmpTmpDblsDelimFile"        }

#TempFiles/Benefit from being permanent in Scripts Directory.
IF (Test-Path "$GDWFDblsBasedOnHashOnlyDelim")   { RI "$GDWFDblsBasedOnHashOnlyDelim"   }
IF (Test-Path "$GDWFDblsBasedOnHashNFNameDelim") { RI "$GDWFDblsBasedOnHashNFNameDelim" }
IF (Test-Path "$GDWFTempDblsDelimFileDel")       { RI "$GDWFTempDblsDelimFileDel"       }
IF (Test-Path "$GDWFTempDblsDelimFileDelUndo")   { RI "$GDWFTempDblsDelimFileDelUndo"   }
IF (Test-Path "$GDWFTempDblsDelimFileHL")        { RI "$GDWFTempDblsDelimFileHL"        }

#Does nothing unless TempScripts are in script directory.
IF ($DeleteAll)                                                { Return                                                                                  }

#_Main
IF (!($GDWFTabDelimFCIVHashedFile))                                 { Echo "Script Error. Variable GDWFTabDelimFCIVHashedFile is undefined." ; Pause ; Return }
IF (!(Test-Path "$GDWFTabDelimFCIVHashedFile" -PathType Leaf))      { Echo "Script Error. File     GDWFTabDelimFCIVHashedFile doesnt exist." ; Pause ; Return }
IF (!($GDWFRegTweaksDir))                                           { Echo "Script Error. Variable GDWFRegTweaksDir           is undefined." ; Pause ; Return }
IF (!("$YYYYMMDD" -Match "20\d{2}\d{2}\d{2}"))                      { Echo "Script Error. Variable YYYYMMDD                   is undefined." ; Pause ; Return }

#Functions
Function Get-FileFilesCount-ForCD-Recursively {
    $GFFileCTempCount = (GCI -File -Recurse).FullName | Measure-Object | Select-Object Count
    $GFFileCTempCount = ($GFFileCTempCount).Count

    #PowerShell auto assigns zero, but still just in case.
    IF (!($GFFileCTempCount)) { $GFFileCTempCount = "0" }
    $GFFileCTempCount
    }

Function Get-FileLineCount-IfExists {
    param ([String]$GFLCFileIn)
    $GFLCTempCount = (GC $GFLCFileIn).Count

    #PowerShell auto assigns zero, but still just in case.
    IF (!($GFLCTempCount)) { $GFLCTempCount = "0" }
    $GFLCTempCount
    }

#File/Folder Location/CurrentDirectory
$GDWFUserDir = (Get-Item -Path ".\" -Verbose).FullName
IF ("$GDWFUserDir" -ne "$GDWFRegTweaksDir") { $GDWFPushedRegTweaksDirBln = "T" ; SL $GDWFRegTweaksDir }

#Checks on FileIn.
#$GDWFFileInCorrectDelimFormatLinesC = (GC "$GDWFTabDelimFCIVHashedFile" | Select-String -Pattern "^[0-9a-f]*`t[a-z]:\\[a-z0-9\-_\\`~!@#\$\%%^&\*()+=\[\]{}'';,\.]*").Matches.Count
IF (Test-Path "$GDWFTabDelimFCIVHashedFileCopy") { $GDWFTabDelimFCIVHashedFileCopyLC   = Get-FileLineCount-IfExists "$GDWFTabDelimFCIVHashedFileCopy" }

#Copy FileIn, sort it, and ensuring only lines with FCIV Hashes	FileNameFQP is processed.
GC "$GDWFTabDelimFCIVHashedFile" | Sort-Object | Select-String -Pattern "[a-z]:" | Out-File -Encoding ASCII "$GDWFTabDelimFCIVHashedFileCopy"

#Protect scripts from being executed if accidentally being clicked, by writing two lines of code.
Echo "`r`nRead-Host = ""Hit ENTER to Execute""" | Out-File -Encoding ASCII "$GDWFTempDblsDelimFileDel"     
Echo "`r`nRead-Host = ""Hit ENTER to Execute""" | Out-File -Encoding ASCII "$GDWFTempDblsDelimFileDelUndo" 
Echo "`r`nSet /P Wait=Hit ENTER to Execute"     | Out-File -Encoding ASCII "$GDWFTempDblsDelimFileHL"      

#_Main-DisplayCodeGist
IF (!($Quiet)) {
                                             Echo ""
                                             Echo "CodeGist           : List, delete, replace duplicate files from regtweak-master Github project"
                                             Echo "                     create 3 TempScripts to action upon them"
                                             Echo "                     do so in a user prompted and a DebugInformative manner"
                                             Echo "                  1. delete double, 2. replace with Windows HardLinks,"
                                             Echo "                  3. Undo and provide an Undo capability."
                                             Echo "                     Display files that might provide problems for the Batch Create HardLinks TempScript"
                                             Echo "                     Gather FileFiles count before delete, after delete, and after creating hardlinks."
                                             Echo "                     Display FileStats and remind user of importance of the UndoScript."

                                             Echo ""
IF ($OnlySameFileNameFNX)                  { Echo "Definition         : Doubles have to have same hash AND FileNameFNX i.e. SomeFile.txt                               "  }
IF (!($OnlySameFileNameFNX))               { Echo "Definition         : Doubles have to have same hash BUT having the same FileNameFNX i.e. SomeFile.txt DOESNT MATTER."  }

                                             Echo ""
                                             Echo "TempFilesDir       : $GDWFTempFilesPath"
                                             Echo "UndoScript         : $GDWFTempDblsDelimFileDelUndo"

                                             Echo ""
                                             Pause
    }
########################################################################################################################
#_Main-Worker-Procedure 1. Get the doubles.
########################################################################################################################
IF (!(Test-Path "$GDWFTmpTmpDblsDelimFile")) {
    (GC "$GDWFTabDelimFCIVHashedFileCopy" | Select-String -Pattern "[a-z]:") | % { #ForEach % line in the file.
        [Int]$GDWFDblFileCurrLine ++ | Out-Null

        IF ($CurrHash)    {$PrevHash    = "$CurrHash"     }
        IF ($CurrFileFQP) {$PrevFileFQP = "$CurrFileFQP"  }
        IF ($CurrFileFNX) {$PrevFileFNX = "$CurrFileFNX"  }
        IF ($CurrLine)    {$PrevLine    = "$CurrLine"     }

    $CurrHash    = ("$_").Split("`t")[0]
    $CurrFileFQP = ("$_").Split("`t")[1]
    $CurrFileFNX = ("$CurrFileFQP").Split("\")[-1]
    $CurrLine    = "$_"

    IF ("$GDWFDblFileCurrLine" -eq "$GDWFTabDelimFCIVHashedFileCopyLC") { $CurrHash = "g" }

    #Wont execute if hashes not the same.
    IF ("$CurrFileFNX" -eq "$PrevFileFNX")                                { $CurrConsideredSameFileBln = "T" } ELSE { $CurrConsideredSameFileBln = "" }

    #Irrespective of UserDefined ScriptingOptions.
    IF ( ($CurrConsideredSameFileBln)    -AND ("$PrevHash" -eq "$CurrHash") ) { Echo "$PrevLine`t$CurrLine" | Out-File -Append -Encoding ASCII "$GDWFDblsBasedOnHashNFNameDelim" }
    IF ( (!($CurrConsideredSameFileBln)) -AND ("$PrevHash" -eq "$CurrHash") ) { Echo "$PrevLine`t$CurrLine" | Out-File -Append -Encoding ASCII "$GDWFDblsBasedOnHashOnlyDelim"   }

    #With respect to UserDefined/carry out main ThisScriptScriptingOption
    IF ( ($CurrConsideredSameFileBln = "T") -AND (!($OnlySameFileNameFNX)) )  { $CurrConsideredSameFileBln = "T" } ELSE { $CurrConsideredSameFileBln = "" }

    IF ("$PrevHash" -eq "$CurrHash") {
        IF ($CurrConsideredSameFileBln -eq "T") { Echo "$PrevLine`t$CurrLine" | Out-File -Append -Encoding ASCII "$GDWFTempDblsDelimFile"}
        }
     $PrevHash = ""
     $CurrConsideredSameFileBln = ""
    }
}

#Remove unwanted charachters for unchecked null values above.
IF (Test-Path "$GDWFTmpTmpDblsDelimFile" -PathType Leaf) { GC "$GDWFTmpTmpDblsDelimFile" | Select-String -Pattern "[a-z]:" | Out-File -Encoding ASCII "$GDWFTempDblsDelimFile" }

[Int]$GDWFDblFileCurrLine = 0
########################################################################################################################
#_Main-Worker-Procedure 2. Create Temp Scripts to operate on doubles, in a manner in which File/Folder OPs can be undone.
########################################################################################################################
IF (Test-Path "$GDWFTempDblsDelimFile" -PathType Leaf) {
(GC "$GDWFTempDblsDelimFile") | % { #ForEach % line in the file.
    [Int]$GDWFDblFileCurrLine ++ | Out-Null
    $CurrSrcTgt = ("$_").Split("`t")[1]
    $CurrDest   = ("$_").Split("`t")[3]

    IF ($CurrDest) {
        Echo "RI ""$CurrDest"""                        | Out-File -Append -Encoding ASCII "$GDWFTempDblsDelimFileDel"
        Echo "MKLink /H ""$CurrDest"" ""$CurrSrcTgt""" | Out-File -Append -Encoding ASCII "$GDWFTempDblsDelimFileHL"
        Echo "Copy ""$CurrSrcTgt"" ""$CurrDest"""      | Out-File -Append -Encoding ASCII "$GDWFTempDblsDelimFileDelUndo"
    }

    $CurrSrcTgt = ""
    $CurrDest   = ""

    }
}

#Windows Batch Scripting Problem Tokens.
IF ( ($Testing) -AND (Test-Path "$GDWFTempDblsDelimFileHL") )      {
    Echo ""
    Echo "Displaying files that might provide problems for the Batch Create HardLinks TempScript."
    (GC "$GDWFTempDblsDelimFileHL") | Select-String -Pattern "[\^&()\|]"

    Echo ""
    PAUSE
    }

IF (Test-Path "$GDWFTempDblsDelimFileDel")       { $GDWFTempDblsDelimFileDelC    = (GC "$GDWFTempDblsDelimFileDel"       | Select-String -Pattern "[a-z]:").Count}
IF (Test-Path "$GDWFTempDblsDelimFileDelUndo")   { $GDWFTempDblsDelimFileDelUndo = (GC "$GDWFTempDblsDelimFileDelUndo"   | Select-String -Pattern "[a-z]:").Count}
IF (Test-Path "$GDWFTempDblsDelimFileHL")        { $GDWFTempDblsDelimFileHLC     = (GC "$GDWFTempDblsDelimFileHL"        | Select-String -Pattern "[a-z]:").Count}

#Delete TempScripts if there are no doubles by checking for two lines of code written earlier.
IF ( "$GDWFTempDblsDelimFileDel"     -le "2") { RI "$GDWFTempDblsDelimFileDel"     }
IF ( "$GDWFTempDblsDelimFileDelUndo" -le "2") { RI "$GDWFTempDblsDelimFileDelUndo" }
IF ( "$GDWFTempDblsDelimFileHLC"     -le "2") { RI "$GDWFTempDblsDelimFileHLC"     }


IF ($Testing) {
    #View/DoubleCheck/Analyze the results in a TextEditor.
    IF (Test-Path "$GDWFTempDblsDelimFile")          { & NotePad "$GDWFTempDblsDelimFile"          }
    IF (Test-Path "$GDWFDblsBasedOnHashOnlyDelim")   { & NotePad "$GDWFDblsBasedOnHashOnlyDelim"   }
    IF (Test-Path "$GDWFDblsBasedOnHashNFNameDelim") { & NotePad "$GDWFDblsBasedOnHashNFNameDelim" }

    IF (Test-Path "$GDWFTempDblsDelimFileDel")       { & NotePad "$GDWFTempDblsDelimFileDel"       }
    IF (Test-Path "$GDWFTempDblsDelimFileDelUndo")   { & NotePad "$GDWFTempDblsDelimFileDelUndo"   }
    IF (Test-Path "$GDWFTempDblsDelimFileHL")        { & NotePad "$GDWFTempDblsDelimFileHL"        }
    }

#FileStats-Initial
IF (Test-Path "$GDWFTempDblsDelimFile"          -PathType Leaf) { $GDWFFilesCBefore               = Get-FileFilesCount-ForCD-Recursively                                    }
IF (Test-Path "$GDWFTempDblsDelimFile"          -PathType Leaf) { $GDWFDblFilesC                  = Get-FileLineCount-IfExists "$GDWFTempDblsDelimFile"          }
IF (Test-Path "$GDWFDblsBasedOnHashOnlyDelim"   -PathType Leaf) { $GDWFDblBasedOnHashOnlyFilesC   = Get-FileLineCount-IfExists "$GDWFDblsBasedOnHashOnlyDelim"   }
IF (Test-Path "$GDWFDblsBasedOnHashNFNameDelim" -PathType Leaf) { $GDWFDblBasedOnHashNFNameFilesC = Get-FileLineCount-IfExists "$GDWFDblsBasedOnHashNFNameDelim" }

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
                                             Echo "FileFilesCBefore   : $GDWFFilesCBefore"
                                             Echo "FileFilesCAfter    : $GDWFFilesCAfter"
                                             Echo "FileFilesCNow      : $GDWFFilesCNow"
                                             Echo "DblFileFilesC      : $GDWFDblFilesC"
                                             Echo "DblBasedOnHashOnly : $GDWFDblBasedOnHashOnlyFilesC"
                                             Echo "DblHashNSameFName  : $GDWFDblBasedOnHashNFNameFilesC"

                                             Echo ""
IF ($OnlySameFileNameFNX)                  { Echo "Definition         : Doubles have to have same hash AND FileNameFNX i.e. SomeFile.txt                               "  }
IF (!($OnlySameFileNameFNX))               { Echo "Definition         : Doubles have to have same hash BUT having the same FileNameFNX i.e. SomeFile.txt DOESNT MATTER."  }

                                             Echo ""
                                             Echo "TempDeleteScript   : Executed         $GDWFTempDblsDelimFileDel"
                                             Echo "TempHardLnkScript  : Executed         $GDWFTempDblsDelimFileHL"
                                             Echo "TempDelUndoScript  : Ready for use    $GDWFTempDblsDelimFileDelUndo"
                                             Echo "                     Save this.                                    "
    }

IF ("$GDWFPushedRegTweaksDirBln" -eq "T")          { SL "$GDWFUserDir"                    }

#TempFiles in UserTempFldr/Disposable for sure.
IF (!($Testing)) {
    IF (Test-Path "$GDWFTempDblsDelimFile")          { RI "$GDWFTempDblsDelimFile"          }
    IF (Test-Path "$GDWFTmpTmpDblsDelimFile")        { RI "$GDWFTmpTmpDblsDelimFile"        }
    }

#TempFiles/Benefit from being permanent in Scripts Directory.
IF (Test-Path "$GDWFDblsBasedOnHashOnlyDelim")   { RI "$GDWFDblsBasedOnHashOnlyDelim"   }
IF (Test-Path "$GDWFDblsBasedOnHashNFNameDelim") { RI "$GDWFDblsBasedOnHashNFNameDelim" }

#IF (Test-Path "$GDWFTempDblsDelimFileDel")     { RI "$GDWFTempDblsDelimFileDel"     }
#IF (Test-Path "$GDWFTempDblsDelimFileDelUndo") { RI "$GDWFTempDblsDelimFileDelUndo" }
#IF (Test-Path "$GDWFTempDblsDelimFileHL")      { RI "$GDWFTempDblsDelimFileHL"      }

