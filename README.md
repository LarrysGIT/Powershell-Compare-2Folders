# Powershell-Compare-2Folders

### Usage

`-Path1 C:\1`: Path to the 1st folder

`-Path2 C:\2`: Path to the 2nd folder

`-Path1Name 111`: Default `#1`, change the default header name of path1

`-Path2Name 222`: Default `#2`, change the default header name of path2

`-Directory`: Default `$false`, compare subfolders by existence

`-File`: Default `$true`, compare subfiles by hash, hash is from `Get-FileHash`

`-UseLastModifiedDateInsteadOfHash`: Default `$false`, use `LastWriteTimeUtc` property to compare files, files can have different `LastWriteTimeUtc` but hash reminds

`-OutputDifferenceOnly`: Default `$true`, output only differences

`-Recurse`: Default `$true`, recurse child items

`-CopyDifferentFilesTo`: Default `null`, provide a directory path to copy different files

`-CopyDifferentFilesTo_CopyMode`: Default `AppendNumber`, when file names are conflict (same file name from different dirs), the action to take, `MaintainPathNameForConflictsOnly` maintain the dir name for conflict files, `MaintainPathNameForAll` maintain the dir name for all files, dir name `\` is replaced by `~`

### Samples

```powershell
PS> . .\Compare-2Folders.ps1
PS> # Compare files in 2 folders
PS> Compare-2Folders -Path1 .\1 -Path2 .\2

#1     #2     Type State
--     --     ---- -----
\2.ps1 \2.ps1 File Different

PS> # Compare sub folders, exclude files in 2 folders
PS> Compare-2Folders -Path1 .\1 -Path2 .\2 -Directory -File:$false

#1 #2 Type      State
-- -- ----      -----
   \5 Directory #2

PS> # Output identical files as well
PS> Compare-2Folders -Path1 .\1 -Path2 .\2 -OutputDifferenceOnly:$false

#1     #2     Type State
--     --     ---- -----
\1.ps1 \1.ps1 File Identical
\2.ps1 \2.ps1 File Different

PS> # Use file fullpath instead of relative path
PS> Compare-2Folders -Path1 .\1 -Path2 .\2 -OutputDifferenceOnly:$false -OutputFullName

#1                                    #2                                    Type State
--                                    --                                    ---- -----
C:\workspace\Compare-2Folders\1\1.ps1 C:\workspace\Compare-2Folders\2\1.ps1 File Identical
C:\workspace\Compare-2Folders\1\2.ps1 C:\workspace\Compare-2Folders\2\2.ps1 File Different

PS> # Compare sub items recursly
PS> Compare-2Folders -Path1 .\1 -Path2 .\2 -Recurse

#1     #2     Type State
--     --     ---- -----
\2.ps1 \2.ps1 File Different
       \4.ps1 File #2

PS> Compare-2Folders -Path1 .\1 -Path2 .\2 -Path1Name "P1" -Path2Name "P2"

P1      P2      Type State
--      --      ---- -----
1\2.ps1 2\2.ps1 File Different

PS> Compare-2Folders -Path1 .\1\ -Path2 .\2\ -Path1Name 111 -Path2Name 222 -Recurse -CopyDifferentFilesTo .\copyfiles

111     222       Type State
---     ---       ---- -----
1\2.ps1 2\2.ps1   File Different
        2\3\4.ps1 File 222
```
