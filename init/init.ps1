#Initialized and connect Gogs and Jenkins
param(
  $gogs_url = "http://gogs:3000",
  $gogs_host = "gogs",
  $jenkins_url = "http://jenkins:8080",
  $admin_username = "ccadmin",
  $admin_email = "ccadmin@abc.com",
  $admin_password = "123",
  $templates_path = "/platform-templates",
  $coder_platforms_path = "/home/coder/platforms",
  $force_recreate_template = $false)

function get-gogs-token($token_username, $token_password, $token_name) {
  # Create token if necessary
  $tokens = curl -u "$($token_username):$($token_password)" $gogs_url/api/v1/users/$token_username/tokens
  $tokensArray = $tokens | ConvertFrom-Json
  if ($tokensArray | where { $_.name -eq $token_name }) {
    Write-Information "Token $token_name for user $token_username already exists" -InformationAction Continue
  } else {
    Write-Information "Creating access token $token_name for user $token_username" -InformationAction Continue
    $pair = "$($token_username):$($token_password)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"
    $headers = @{Authorization = $basicAuthValue }
    $Body = '{"name":"' + $token_name + '"}'
    Invoke-WebRequest -Uri "$gogs_url/api/v1/users/$token_username/tokens" -Headers $headers -Method POST -ContentType "application/json" -Body $body | out-null
  }

  # Retrieve the access token
  $token = $((curl -u "$($token_username):$($token_password)" $gogs_url/api/v1/users/$token_username/tokens | convertFrom-json).sha1 | select-object -first 1)
  Write-Information "Token: $token" -InformationAction Continue
  return $token
}

function add-ssh-pubkey-to-gogs-user($username, $password, $keyname, $pubkey) {
  $token = get-gogs-token -token_username $username -token_password $password -token_name "temptoken"
  $Headers = @{Authorization = "token $token" }
  $keys = Invoke-WebRequest -Uri "$gogs_url/api/v1/user/keys" -Headers $Headers
  $keysArray = $keys | convertFrom-json
  if ($keysArray | where {$_.title -eq $keyname}) {
    Write-Host "$keyname already exists for user $username"
  } else {
    Write-Host "Registering $keyname for user $username"
    $body = '{"title":"' + $keyname + '", "key": "' + $pubkey + '"}'
    Invoke-WebRequest -Uri "$gogs_url/api/v1/user/keys" -Headers $Headers -Method POST -ContentType "application/json" -Body $body
  }
}

Write-Host "gogs_url: $gogs_url"
Write-Host "jenkins_url: $jenkins_url"
Write-Host "Admin user: $admin_username"
$jenkins_username = "jenkins"
$jenkins_password = $admin_password

# Wait for gogs to become available
$statusCode = ""
do {
  Write-Host "Waiting for gogs to become available - $statusCode"
  Start-Sleep 5
  $statusCode = $(curl $gogs_url -s -o /dev/null -w "%{http_code}")
} until($statusCode -eq 200)
Write-Host "Gogs is up and running ($statusCode), starting configuration"

# Create the first admin user and the jenkins user
docker exec -u git devops-factory-control-center-gogs-1 ./gogs admin create-user --name="$admin_username" --password="$admin_password" --email="$admin_email" --admin
docker exec -u git devops-factory-control-center-gogs-1 ./gogs admin create-user --name="$jenkins_username" --password="$jenkins_password" --email="dummy@jenkins.com" --admin
add-ssh-pubkey-to-gogs-user -username $jenkins_username -password $jenkins_password -keyname "jenkins-gogs-sshpublickey" -pubkey "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7P2N1mTzUuhra66E05uh3tyB/Tvm1gZj6y0vdUhvlRefRj7nJARmd/O0yhpE6rmfUnBVvyNuYx+dgXlnWZGh+lWhuyybc3qWMCBgTJ4RArAwimhJDAZmeb3h1FDRrEjvnR0UvO+stw7sK+sX+Ud+kAQ7XJy+XzT5S0QCp/Xzabl7UXAZVCL0qvtdPGHcv5jcrXsnISUIU0pLt7vIR2kZxbGp09A1XxYwJYLJjdFGduW7kKtGg/K7dBZEHl71nTW+Ikc5fD6kfC9o8y3JYQoXPdkbhiGEJmSrQnssuMS3EFUiooXgupohmSBx1/xQ8huOXJN3bsJ8WhJVeByODU+Ap jenkins-gogs"

# Create a repository and a Jenkins job per template
foreach ($template in Get-ChildItem -Path "$templates_path") {
  $templatename = $template.Name
  Write-Host "Installing platform template - $templatename" -ForegroundColor Yellow

  # Check if the repo is already there and should be reset
  $admin_token = get-gogs-token -token_username $admin_username -token_password $admin_password -token_name "admin-token"
  $Headers = @{Authorization = "token $admin_token" }
  $repos = Invoke-WebRequest -Uri "$gogs_url/api/v1/user/repos" -Headers $Headers
  $reposArray = convertFrom-json $repos
  $createRepo = $null
  if ($reposArray | where {$_.name -eq $templatename}) {
    Write-Host "Template $templatename already exists"
    $reposArray | fl
    if ($force_recreate_template -eq $true) {
      Write-Host "Resetting template $templatename"
      Invoke-WebRequest -Uri "$gogs_url/api/v1/repos/$admin_username/$templatename" -Headers $Headers -Method DELETE
      $createRepo = $true
    } else {
      Write-Host "Template won't be reset"
      $createRepo = $false
    }
  } else {
    $createRepo = $true
  }

  if ($createRepo) {
    # create the repository
    Write-Host "Creating repository for tempalte $templatename"  -ForegroundColor DarkCyan
    $body = '{"name":"' + $templatename + '"}'
    Invoke-WebRequest -Uri "$gogs_url/api/v1/user/repos" -Headers $Headers -Method POST -ContentType "application/json" -Body $body 

    # Create webhook
    $hooks = Invoke-WebRequest -Uri "$gogs_url/api/v1/repos/$admin_username/$templatename/hooks" -Headers $Headers
    if ($hooks.Content -eq "[]") {
      $body = '{ "type":"gogs", "config":{"url":"http://jenkins:8080/gogs-webhook/?job=' + $templatename + '", "content_type": "json"}, "events":["push"], "active":true }'
      Invoke-WebRequest -Uri "$gogs_url/api/v1/repos/$admin_username/$templatename/hooks" -Headers $Headers -Method POST -ContentType "application/json" -Body $body
    }

    # Create a ssh key to be used by the init container & coder to access Gogs using ssh
    if (!(Test-Path ~/.ssh/id_rsa.pub)) {
      Write-Host "Creating init container ssh key" -ForegroundColor DarkCyan
      docker exec -u coder devops-factory-control-center-codeserver-1 ssh-keygen -t rsa -b 1024 -f /home/coder/.ssh/id_rsa -q -N '""'
      docker exec -u coder devops-factory-control-center-codeserver-1 ssh-keyscan -H $gogs_host >> /home/coder/.ssh/known_hosts
    
      Write-Host "Displaying /home/coder/.ssh content"  -ForegroundColor DarkCyan
      docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "ls /home/coder/.ssh -ls"
    }

    Write-Host "Adding init container ssh key to gogs" -ForegroundColor DarkCyan
    get-childitem /home/coder/.ssh
    $currentUserSshKey = get-content -path "/home/coder/.ssh/id_rsa.pub"
    Invoke-WebRequest -Uri "$gogs_url/api/v1/user/keys" -Headers $Headers -Method POST -ContentType "application/json" -Body "{`"title`":`"${admin_username}_coder`", `"key`":`"$currentUserSshKey`"}"

    Write-Host "Configuring coder git" -ForegroundColor DarkCyan
    docker exec -u coder devops-factory-control-center-codeserver-1 git config --global user.email $admin_email
    docker exec -u coder devops-factory-control-center-codeserver-1 git config --global user.name "Initialization script"

    # Write-Host "Cleaning $coder_platforms_path"
    # Get-ChildItem -Path $coder_platforms_path -Recurse| Foreach-object { Remove-item -Recurse -path $_.FullName }

    Write-Host "Cloning $templatename in coder" -ForegroundColor DarkCyan
    docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "echo 'ssh folder content:' && ls /home/coder/.ssh -ls"
    docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "echo '/home/coder/platforms folder content:' && ls /home/coder/platforms -ls"
    # docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "rm -rf /home/coder/platforms"
    docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "echo 'cloning' && cd /home/coder/platforms && ls -la && git clone git@${gogs_host}:$admin_username/$templatename.git"
    start-sleep 5 # wait until the clone operation is finished

    Write-Host "Add template files to local repository" -ForegroundColor DarkCyan
    dir $templates_path
    dir $templates_path/$templatename
    Copy-Item -Path $templates_path/$templatename -Destination $coder_platforms_path -Recurse -Force
    docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "ls $coder_platforms_path -ls"

    Write-Host "git add"
    docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "cd /home/coder/platforms/$templatename && git add ."

    Write-Host "git commit"
    docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "cd /home/coder/platforms/$templatename && git commit -m 'Initial commit'"

    Write-Host "git push"
    docker exec -u coder devops-factory-control-center-codeserver-1 bash -c "cd /home/coder/platforms/$templatename && git push"

    # Create the Jenkins job according to the template Jenkins-pieline-config.xml file
    Write-Host "Creating Jenkins job" -ForegroundColor DarkCyan
    $crumb_request = curl -u ${admin_username}:${admin_password} $jenkins_url/crumbIssuer/api/json
    $jenkins_crumb = ($crumb_request | ConvertFrom-Json).crumb
    $pair = "${admin_username}:${admin_password}"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"
    $headers = @{Authorization = $basicAuthValue; "Jenkins-Crumb" = "$jenkins_crumb" }
    $uri = "$jenkins_url/createItem?name=$templatename"
    $body = Get-Content -Path "$templates_path/$templatename/Jenkins-pipeline-config.xml" -Encoding ASCII
    Invoke-RestMethod -Uri $uri -Method POST -ContentType "application/xml" -Body $body -Headers $headers
  }
}

# Replace the code server password with the one provided
Write-Host "Replacing the ccadmin password in the local folder /home/coder/config/config.yaml" -ForegroundColor DarkCyan
$configLines = Get-Content -Path "/home/coder/config/config.yaml" -Encoding ASCII
$output = @()
$configLines | ForEach-Object { 
  if ($_ -match "password:") {
    $output += "password: $admin_password"
  } else {
    $output += $_
  } 
} 
$output | Set-Content -Path "/home/coder/config/config.yaml" -Encoding ASCII
docker restart devops-factory-control-center-codeserver-1

