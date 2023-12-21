FROM jenkins/jenkins:2.435
ARG admin_username
ARG admin_password

# skip the setup wizard
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false"

# install plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins_casc.yml /var/jenkins_casc.yml

USER root
RUN sed -i "s/#admin_username#/${admin_username}/g" /var/jenkins_casc.yml
RUN sed -i "s/#admin_password#/${admin_password}/g" /var/jenkins_casc.yml

ENV DOCKERVERSION=18.03.1-ce
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

RUN jenkins-plugin-cli --clean-download-directory --list --view-security-warnings -f /usr/share/jenkins/ref/plugins.txt
