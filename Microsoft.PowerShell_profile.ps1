# oh-my-posh config
oh-my-posh init pwsh --config ~\AppData\Local\Programs\oh-my-posh\themes\M365Princess.omp.json | Invoke-Expression

# command alias
Set-Alias g git
Set-Alias dkcp docker-compose
Set-Alias dk docker

# jabba config
if (Test-Path "C:\Users\3104k\.jabba\jabba.ps1") { . "C:\Users\3104k\.jabba\jabba.ps1" }
jabba use adopt@1.16.0-1