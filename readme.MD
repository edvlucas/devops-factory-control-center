# About the Control Center

The code is this repo is described in this [article](https://medium.com/p/3890e30f0734).

# Running the Control Center

## From Windows / PowerhShell

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
