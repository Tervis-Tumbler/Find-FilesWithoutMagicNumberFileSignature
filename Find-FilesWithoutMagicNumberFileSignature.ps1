Function Find-FilesWithoutMagicNumberFileSignature {
<#    
.SYNOPSIS    
    Finds all files recursively under $RootScanPath and then feeds them to file.exe (a windows compiled version of http://unixhelp.ed.ac.uk/CGI/man-cgi?file) to
    see if the file matches a known magic number/file signature and writes out a list of all those files that do not

    To obtain the needed file.exe and its depedencies you will need to obtain it through cygwin (choco install cygwin)
    or through GNUWin32 (choco install gnuwin). GNUWin32 has a version 3 years older than cygwin so use cygwin if possible.

    If you don't know how to use choco install please check out Chocolatey at https://chocolatey.org/

    If you have been attached by ransomware like Cryptowall 
    then the files in the output list are possibly encrypted by ransomware especially if you see files with
    extensions like .doc, xlsx, jpg, etc.

    More information on magic numbers (http://en.wikipedia.org/wiki/Magic_number_(programming)) and file signatures (http://en.wikipedia.org/wiki/List_of_file_signatures)
.DESCRIPTION  
    Finds files with no known magic number/file signature. 
    
    If you have been attached by ransomware like Cryptowall 
    then these files are also files that were possibly encrypted by this ransomware especially if you see files with
    extensions like .doc, xlsx, jpg, etc. then it is more than likely these have been encrypted by the ransomware.
.PARAMETER PathToFileDotExe  
    Path to the File.exe you are going to be using. See the synopsis section of get-help Find-FilesWithoutMagicNumberFileSignature for more information on how to obtain file.exe
.PARAMETER RootScanPath
    The starting root folder to begin searching for files in itself and recursively through all subdirectories
.PARAMETER AllFilesLogFile
    The file where the the log of all files are going to be scanned will be stored. This file is written out with Unix EOL format as that is 
    what is required by file.exe so if you want to use it for another purpose open it in notepad++ (choco install notepadplusplus.install)
    and then navigate to Edit > EOL Conversion > Windows Format and then save as another copy or run
    (Get-Content "C:\path\to\AllFilesLogFile.txt") | Set-Content "C:\path\to\AllFilesLogFileWindows.txt"
    http://stackoverflow.com/questions/17579553/windows-command-to-convert-unix-eol-to-windows-eol
.PARAMETER FileDotExeResultsLogFile
    The file where the results of file.exe running on each individual file will be logged.
.PARAMETER FilesWithoutMagicNumberFileSignatureLogFile
    Files that were scaned with file.exe but did not have any matching magic number/file signature known to libmagic.
.EXAMPLE    
    Find-FilesWithoutMagicNumberFileSignature -PathToFileDotExe "C:\cygwin64\bin\file.exe" -RootScanPath "C:\Users\cmagnuson\Desktop\TestInfectionDetection" -AllFilesLogFile "C:\Users\cmagnuson\Documents\ScanResults\AllFiles.csv" -FileDotExeResultsLogFile "C:\Users\cmagnuson\Documents\ScanResults\FileDotExeResults.csv" -FilesWithoutMagicNumberFileSignatureLogFile "C:\Users\cmagnuson\Documents\ScanResults\FilesWithoutMagicNumberFileSignature.csv"
   
    Description
    -----------
    Uses "C:\cygwin64\bin\file.exe" to scan each file found in "C:\Users\cmagnuson\Desktop\TestInfectionDetection" and its subdirectories recursively logging each file found to "C:\Users\cmagnuson\Documents\ScanResults\AllFiles.csv" and the results of the file.exe command to "C:\Users\cmagnuson\Documents\ScanResults\FileDotExeResults.csv" with a final list of all files that didn't have a magic number/file signature logged to "C:\Users\cmagnuson\Documents\ScanResults\FilesWithoutMagicNumberFileSignature.csv".

    This will often be followed by doing analysis on "C:\Users\cmagnuson\Documents\ScanResults\FilesWithoutMagicNumberFileSignature.csv" using something like the following:
    $PossiblyEncryptedFiles = Get-Content "C:\Users\cmagnuson\Documents\ScanResults\FilesWithoutMagicNumberFileSignature.csv"
    $PossiblyEncryptedFiles | Measure-Object #How many files did we find without a matching signature?

    $FileInfos = $PossiblyEncryptedFiles | % { [System.IO.FileInfo]$_ }
    $FileInfos | group extension | sort count -Descending #What was the most common file extensions amoung those that didn't match a signature?
    $FileInfos | where extension -eq ".xls" | select fullname #Where are the .xls files that didn't match a signature?
#>
    param(
        $PathToFileDotExe,
        $RootScanPath,
        $AllFilesLogFile,        
        $FileDotExeResultsLogFile,
        $FilesWithoutMagicNumberFileSignatureLogFile
    )
    $AllFiles = gci $RootScanPath -Recurse | where PsIsContainer -eq $false

    $StreamWriter = [System.IO.StreamWriter]$AllFilesLogFile
    $AllFiles | % {
        #Write out files with unix end of line (EOL) so that file.exe can read them properly
        $StreamWriter.Write( $($_.FullName + "`n") ) 
    }
    $StreamWriter.close()

    $FileDotExeResults = & $PathToFileDotExe --no-pad --files-from $AllFilesLogFile

    $FileDotExeResults | Out-String | Out-File $FileDotExeResultsLogFile

    $FilesWithoutMagicNumberFileSignature = foreach ($FileDotExeResult in $FileDotExeResults) { 
        if ($($($FileDotExeResult) -split ": ")[1] -EQ "data" ) {
            $($($FileDotExeResult) -split ": ")[0]
        }    
    }

    $FilesWithoutMagicNumberFileSignature | Out-String | Out-File $FilesWithoutMagicNumberFileSignatureLogFile
}
