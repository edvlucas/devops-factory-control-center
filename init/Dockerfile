FROM mcr.microsoft.com/powershell:lts-ubuntu-18.04
# ENV admin_username "123"

# Install the docker cli and git
ENV DOCKERVERSION=20.10.9
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz
RUN apt-get update && apt-get install git -y

# Run the initialization script when the container starts
COPY init.ps1 /init.ps1
ENTRYPOINT pwsh -c /init.ps1 -gogs_url ${gogs_url} -jenkins_url ${jenkins_url} -admin_username ${admin_username} -admin_password ${admin_password} -admin_email ${admin_email}
