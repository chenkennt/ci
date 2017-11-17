FROM jenkins/jenkins:alpine

MAINTAINER vscjenkins@microsoft.com

WORKDIR /var/jenkins_home

ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

COPY . /opt

RUN /opt/bash/bootstrap-jenkins.sh

USER root

RUN apk update
RUN apk add perl

ARG JENKINS_REMOTING_VERSION=3.12

# See https://github.com/jenkinsci/docker-slave/blob/2.62/Dockerfile#L32
RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/$JENKINS_REMOTING_VERSION/remoting-$JENKINS_REMOTING_VERSION.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar

COPY jenkins-slave /usr/local/bin/jenkins-slave

RUN chmod 755 /usr/local/bin/jenkins-slave

WORKDIR /home/jenkins
RUN chmod a+rwx /home/jenkins
USER jenkins

ARG AGENT_WORKDIR=/home/jenkins/agent
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/jenkins/.jenkins && mkdir -p ${AGENT_WORKDIR}
VOLUME /home/jenkins/.jenkins
VOLUME ${AGENT_WORKDIR}

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
