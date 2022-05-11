# Invoke the init script locally from a PowerShell core session (instead of from the docker-composition init container) - for debugging purposes
./init.ps1 -gogs_url http://localhost:3000 -gogs_host localhost -jenkins_url http://localhost:8080 -templates_path $PSScriptRoot/../platform-templates -force_recreate_template $true
