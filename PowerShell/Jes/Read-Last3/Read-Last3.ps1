foreach ($line in ($list = gc file.txt)) { if ($line.ReadCount -gt ($list.Count - 3)) { $line } }