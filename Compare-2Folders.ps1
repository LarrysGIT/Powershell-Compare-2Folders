function Compare-2Folders
{
    PARAM(
        [string]$Path1,
        [string]$Path2,
        [string]$Path1Name = "#1",
        [string]$Path2Name = "#2",
        [switch]$Directory,
        [switch]$File = $true,
        [switch]$UseLastModifiedDateInsteadOfHash,
        [switch]$OutputDifferenceOnly = $true,
        [string]$CopyDifferentFilesTo,
        [ValidateSet('MaintainPathNameForConflictsOnly', 'MaintainPathNameForAll','AppendNumber')][string]$CopyDifferentFilesTo_CopyMode,
        [switch]$Recurse
    )

    $f1 = Get-Item -Path $Path1.TrimEnd('\') -ErrorAction:SilentlyContinue
    if(!$f1 -or $f1.Mode -notmatch '^d')
    {
        Throw "'$Path1' is not a folder"
    }
    $s1_file = Get-ChildItem -Path $f1.FullName -File -Recurse:$Recurse
    $s1_directory = Get-ChildItem -Path $f1.FullName -Directory -Recurse:$Recurse

    $f2 = Get-Item -Path $Path2.TrimEnd('\') -ErrorAction:SilentlyContinue
    if(!$f2 -or $f2.Mode -notmatch '^d')
    {
        Throw "'$Path2' is not a folder"
    }
    $s2_file = Get-ChildItem -Path $f2.FullName -File -Recurse:$Recurse
    $s2_directory = Get-ChildItem -Path $f2.FullName -Directory -Recurse:$Recurse

    $obj = New-Object PSObject -Property @{"$Path1Name" = $null; "Path1FullName" = $null; "$Path2Name" = $null; "Path2FullName" = $null; "State" = $null; "Type" = $null}

    if($File)
    {
        $h1 = @{}
        $h2 = @{}
        if($UseLastModifiedDateInsteadOfHash)
        {
            $s1_file | %{
                $h1[$($_.FullName.Replace($f1.FullName, ""))] = $_.LastWriteTimeUtc.Ticks
            }
            $s2_file | %{
                $h2[$($_.FullName.Replace($f2.FullName, ""))] = $_.LastWriteTimeUtc.Ticks
            }
        }
        else
        {
            $s1_file | %{
                $h1[$($_.FullName.Replace($f1.FullName, ""))] = (Get-FileHash -Path $_.FullName).Hash
            }
            $s2_file | %{
                $h2[$($_.FullName.Replace($f2.FullName, ""))] = (Get-FileHash -Path $_.FullName).Hash
            }
        }

        $h1.Keys + $h2.Keys | Sort-Object -Unique | %{
            if($h1.ContainsKey($_) -and $h2.ContainsKey($_))
            {
                if($h1[$_] -eq $h2[$_]) # file exists on both place
                {
                    if(!$OutputDifferenceOnly)
                    {
                        $NewObj = $obj.PSObject.Copy()
                        $NewObj.Path1FullName = Join-Path -Path $f1.FullName -ChildPath $_
                        $NewObj.Path2FullName = Join-Path -Path $f2.FullName -ChildPath $_
                        $NewObj.$Path1Name = Join-Path -Path $f1.Name -ChildPath $_
                        $NewObj.$Path2Name = Join-Path -Path $f2.Name -ChildPath $_
                        $NewObj.'State' = 'Identical'
                        $NewObj.'Type' = 'File'
                        $NewObj
                    }
                }
                else
                {
                    $NewObj = $obj.PSObject.Copy()
                    $NewObj.Path1FullName = Join-Path -Path $f1.FullName -ChildPath $_
                    $NewObj.Path2FullName = Join-Path -Path $f2.FullName -ChildPath $_
                    $NewObj.$Path1Name = Join-Path -Path $f1.Name -ChildPath $_
                    $NewObj.$Path2Name = Join-Path -Path $f2.Name -ChildPath $_
                    $NewObj.'State' = 'Different'
                    $NewObj.'Type' = 'File'
                    $NewObj
                    if($CopyDifferentFilesTo)
                    {
                        if(!(Test-Path "$CopyDifferentFilesTo\diff" -PathType Container))
                        {
                            New-Item -Path "$CopyDifferentFilesTo\diff" -ItemType Directory -Force -ErrorAction:SilentlyContinue | Out-Null
                        }
                        $i = 1
                        while($true)
                        {
                            if($CopyDifferentFilesTo_CopyMode -in @("MaintainPathNameForConflictsOnly", "MaintainPathNameForAll"))
                            {
                                $CopyTo_1 = "$CopyDifferentFilesTo\diff\$(Split-Path $NewObj.$Path1Name -Leaf)_$((Split-Path $NewObj.$Path1Name).Replace("\", "~"))_$Path1Name"
                                $CopyTo_2 = "$CopyDifferentFilesTo\diff\$(Split-Path $NewObj.$Path2Name -Leaf)_$((Split-Path $NewObj.$Path2Name).Replace("\", "~"))_$Path2Name"
                            }
                            else
                            {
                                $CopyTo_1 = "$CopyDifferentFilesTo\diff\$(Split-Path $NewObj.$Path1Name -Leaf)_SameNameConflict$('{0:D2}' -f $i)_$Path1Name"
                                $CopyTo_2 = "$CopyDifferentFilesTo\diff\$(Split-Path $NewObj.$Path2Name -Leaf)_SameNameConflict$('{0:D2}' -f $i)_$Path2Name"
                            }
                            if($i -eq 1)
                            {
                                if($CopyDifferentFilesTo_CopyMode -in @("MaintainPathNameForAll"))
                                {
                                    $CopyTo_1 = "$CopyDifferentFilesTo\diff\$(Split-Path $NewObj.$Path1Name -Leaf)_$((Split-Path $NewObj.$Path1Name).Replace("\", "~"))_$Path1Name"
                                    $CopyTo_2 = "$CopyDifferentFilesTo\diff\$(Split-Path $NewObj.$Path2Name -Leaf)_$((Split-Path $NewObj.$Path2Name).Replace("\", "~"))_$Path2Name"
                                }
                                else
                                {
                                    $CopyTo_1 = "$CopyDifferentFilesTo\diff\$(Split-Path $NewObj.$Path1Name -Leaf)_$Path1Name"
                                    $CopyTo_2 = "$CopyDifferentFilesTo\diff\$(Split-Path $NewObj.$Path2Name -Leaf)_$Path2Name"
                                }
                            }
                            $i++
                            if((Test-Path -Path $CopyTo_1) -or (Test-Path -Path $CopyTo_2))
                            {
                                continue
                            }
                            else
                            {
                                break
                            }
                        }
                        Copy-Item -Path $NewObj.Path1FullName -Destination $CopyTo_1
                        Copy-Item -Path $NewObj.Path2FullName -Destination $CopyTo_2
                    }
                }
            }
            elseif($h1.ContainsKey($_) -and !$h2.ContainsKey($_)) # file exists on path1
            {
                $NewObj = $obj.PSObject.Copy()
                $NewObj.Path1FullName = Join-Path -Path $f1.FullName -ChildPath $_
                $NewObj.$Path1Name = Join-Path -Path $f1.Name -ChildPath $_
                #$NewObj.$Path2Name = ""
                $NewObj.'State' = $Path1Name
                $NewObj.'Type' = 'File'
                $NewObj
                if($CopyDifferentFilesTo)
                {
                    if(!(Test-Path "$CopyDifferentFilesTo\$Path1Name" -PathType Container))
                    {
                        New-Item -Path "$CopyDifferentFilesTo\$Path1Name" -ItemType Directory -Force -ErrorAction:SilentlyContinue | Out-Null
                    }
                    $i = 1
                    while($true)
                    {
                        if($CopyDifferentFilesTo_CopyMode -in @("MaintainPathNameForConflictsOnly", "MaintainPathNameForAll"))
                        {
                            $CopyTo_1 = "$CopyDifferentFilesTo\$Path1Name\$(Split-Path $NewObj.$Path1Name -Leaf)_$((Split-Path $NewObj.$Path1Name).Replace("\", "~"))_$Path1Name"
                        }
                        else
                        {
                            $CopyTo_1 = "$CopyDifferentFilesTo\$Path1Name\$(Split-Path $NewObj.$Path1Name -Leaf)_SameNameConflict$('{0:D2}' -f $i)"
                        }
                        if($i -eq 1)
                        {
                            if($CopyDifferentFilesTo_CopyMode -in @("MaintainPathNameForAll"))
                            {
                                $CopyTo_1 = "$CopyDifferentFilesTo\$Path1Name\$(Split-Path $NewObj.$Path1Name -Leaf)_$((Split-Path $NewObj.$Path1Name).Replace("\", "~"))_$Path1Name"
                            }
                            else
                            {
                                $CopyTo_1 = "$CopyDifferentFilesTo\$Path1Name\$(Split-Path $NewObj.$Path1Name -Leaf)"
                            }
                        }
                        $i++
                        if(Test-Path -Path $CopyTo_1)
                        {
                            continue
                        }
                        else
                        {
                            break
                        }
                    }
                    Copy-Item -Path $NewObj.Path1FullName -Destination $CopyTo_1
                }
            }
            elseif(!$h1.ContainsKey($_) -and $h2.ContainsKey($_)) # file exists on path2
            {
                $NewObj = $obj.PSObject.Copy()
                #$NewObj.$Path1Name = ""
                $NewObj.Path2FullName = Join-Path -Path $f2.FullName -ChildPath $_
                $NewObj.$Path2Name = Join-Path -Path $f2.Name -ChildPath $_
                $NewObj.'State' = $Path2Name
                $NewObj.'Type' = 'File'
                $NewObj
                if($CopyDifferentFilesTo)
                {
                    if(!(Test-Path "$CopyDifferentFilesTo\$Path2Name" -PathType Container))
                    {
                        New-Item -Path "$CopyDifferentFilesTo\$Path2Name" -ItemType Directory -Force -ErrorAction:SilentlyContinue | Out-Null
                    }
                    $i = 1
                    while($true)
                    {
                        if($CopyDifferentFilesTo_CopyMode -in @("MaintainPathNameForConflictsOnly", "MaintainPathNameForAll"))
                        {
                            $CopyTo_2 = "$CopyDifferentFilesTo\$Path2Name\$(Split-Path $NewObj.$Path2Name -Leaf)_$((Split-Path $NewObj.$Path2Name).Replace("\", "~"))_$Path2Name"
                        }
                        else
                        {
                            $CopyTo_2 = "$CopyDifferentFilesTo\$Path2Name\$(Split-Path $NewObj.$Path2Name -Leaf)_SameNameConflict$('{0:D2}' -f $i)"
                        }
                        if($i -eq 1)
                        {
                            if($CopyDifferentFilesTo_CopyMode -in @("MaintainPathNameForAll"))
                            {
                                $CopyTo_2 = "$CopyDifferentFilesTo\$Path2Name\$(Split-Path $NewObj.$Path2Name -Leaf)_$((Split-Path $NewObj.$Path2Name).Replace("\", "~"))_$Path2Name"
                            }
                            else
                            {
                                $CopyTo_2 = "$CopyDifferentFilesTo\$Path2Name\$(Split-Path $NewObj.$Path2Name -Leaf)"
                            }
                        }
                        $i++
                        if(Test-Path -Path $CopyTo_2)
                        {
                            continue
                        }
                        else
                        {
                            break
                        }
                    }
                    Copy-Item -Path $NewObj.Path2FullName -Destination $CopyTo_2
                }
            }
        }
    }

    if($Directory)
    {
        $h1 = @{}
        $h2 = @{}
        $s1_directory | %{
            $h1[$($_.FullName.Replace($_.Parent.FullName, ""))] = ""
        }
        $s2_directory | %{
            $h2[$($_.FullName.Replace($_.Parent.FullName, ""))] = ""
        }
        $h1.Keys + $h2.Keys | Sort-Object -Unique | %{
            if($h1.ContainsKey($_) -and $h2.ContainsKey($_))
            {
                if(!$OutputDifferenceOnly)
                {
                    $NewObj = $obj.PSObject.Copy()
                    $NewObj.Path1FullName = Join-Path -Path $f1.FullName -ChildPath $_
                    $NewObj.Path2FullName = Join-Path -Path $f2.FullName -ChildPath $_
                    $NewObj.$Path1Name = Join-Path -Path $f1.Name -ChildPath $_
                    $NewObj.$Path2Name = Join-Path -Path $f2.Name -ChildPath $_
                    $NewObj.'State' = "$Path1Name $Path2Name"
                    $NewObj.'Type' = 'Directory'
                    $NewObj
                }
            }
            elseif($h1.ContainsKey($_) -and !$h2.ContainsKey($_)) # directory exists on path1
            {
                $NewObj = $obj.PSObject.Copy()
                $NewObj.Path1FullName = Join-Path -Path $f1.FullName -ChildPath $_
                $NewObj.$Path1Name = Join-Path -Path $f1.Name -ChildPath $_
                #$NewObj.$Path2Name = ""
                $NewObj.'State' = $Path1Name
                $NewObj.'Type' = 'Directory'
                $NewObj
            }
            elseif(!$h1.ContainsKey($_) -and $h2.ContainsKey($_)) # directory exists on path2
            {
                $NewObj = $obj.PSObject.Copy()
                #$NewObj.$Path1Name = ""
                $NewObj.Path2FullName = Join-Path -Path $f2.FullName -ChildPath $_
                $NewObj.$Path2Name = Join-Path -Path $f2.Name -ChildPath $_
                $NewObj.'State' = $Path2Name
                $NewObj.'Type' = 'Directory'
                $NewObj
            }
        }
    }
}