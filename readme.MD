# About the Control Center

The code is this repo is described in this [article](https://medium.com/@elucas_15434/dev-platform-architecture-part-4-695d9ab3eb4f).

The Control Center contains Jenkins, Gogs, VSCode and some development platform templates.

Jenkins, Gogs and VSCode are pre-configured and connected to each other.

# Running the Control Center

## From Windows / PowerShell

- Install Docker Desktop and Git
- In PowerShell, run:
        git checkout git@github.com:edvlucas/devops-factory-control-center.git
        cd devops-factory-control-center
        .\start.ps1

## From Ubuntu/WSL
- Install Docker and Git
- In a bash console, run:
        git checkout git@github.com:edvlucas/devops-factory-control-center.git
        cd devops-factory-control-center
        ccadminpassword=somepassword docker-compose up

# Control Center services

After running the composition you can access the following services using your web browser:
- Jenkins: http://localhost:8080
- Gogs: http://localhost:3000 - Use the username ccadmin and the password supplied when running start.ps1
- VSCode: http://localhost:8081 - The password is supplied when running start.ps1

# Making changes to the empty-platform platform template
- Open the empty platform code in [VSCode](http://localhost:8081/?folder=/home/coder/platforms/empty-platform)
- Make some changes, save, commit them to Git and push them to Gogs
    - The Jenkins pipeline will be automatically triggered
- Navigate to the [Jenkins pipeline](http://localhost:8080/job/empty-platform/job/master/) to view the platform pipeline execution status and logs

VSCode, Gogs and Jenkins are all pre-configured and connected to each other. You just have to modify you platform files and the associated Jenkins pipeilne will be triggered, allowing you to have a CI/CD environment out-of-the-box.

# Developing a new platform

- Clone one of the platform templates
- Create a new repository in [Gogs](http://localhost:3000/repo/create)
- Use [VSCode](http://localhost:8081) terminal to copy the template to your own folder and commit it to the new Gogs repository
- Create a webhook in [Gogs](http://localhost:3000) pointing to the repository
- Create a [Jenkins](http://localhost:8080) multibranch pipeline pointing to the repository
