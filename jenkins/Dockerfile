FROM jenkins/jenkins:2.344
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

RUN jenkins-plugin-cli --clean-download-directory --list --view-security-warnings -f /usr/share/jenkins/ref/plugins.txt
