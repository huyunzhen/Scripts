﻿if (!(Test-Path "C:\ClassNotes")) { New-Item -ItemType Directory -Path "C:\ClassNotes" | Out-Null }
(1..10) | % { Set-Content -Path $("C:\ClassNotes\File" + $_ + ".txt") -Value $("CLASS:","DATE:","NOTES:") }