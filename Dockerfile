FROM mcr.microsoft.com/oryx/node-8.0:20190508.1
LABEL maintainer="Azure App Services Container Images <appsvc-images@microsoft.com>"

RUN echo "ipv6" >> /etc/modules

# Workaround for https://github.com/npm/npm/issues/16892
# Running npm install as root blows up in a  --userns-remap
# environment.

 RUN npm remove pm2 -g \
     && mkdir -p /opt/startup \
     && chmod -R 777 /opt/startup \
     && mkdir -p /opt/pm2 \
     && chmod 777 /opt/pm2 \
     && chmod 777 -R /usr/local/lib/node_modules \
     && ln -s /opt/pm2/node_modules/pm2/bin/pm2 /usr/local/bin/pm2

 USER node

 RUN cd /opt/pm2 \
  && npm install pm2 -g \
  && cd /opt/startup \
  && npm install

 USER root

 # End workaround

RUN mkdir -p /home/LogFiles /opt/startup \
     && echo "root:Docker!" | chpasswd \
     && echo "cd /home" >> /etc/bash.bashrc \
     && apt-get update \  
     && apt-get install --yes --no-install-recommends openssh-server vim curl wget tcptraceroute openrc

# setup default site
RUN rm -f /etc/ssh/sshd_config
COPY startup /opt/startup
COPY hostingstart.html /opt/startup

# configure startup
RUN mkdir -p /tmp
COPY sshd_config /etc/ssh/

COPY ssh_setup.sh /tmp
RUN chmod -R +x /opt/startup \
   && chmod -R +x /tmp/ssh_setup.sh \
   && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null) \
   && rm -rf /tmp/* \
   && cd /opt/startup 

ENV PORT 8080
ENV SSH_PORT 2222
EXPOSE 2222 8080

ENV PM2HOME /pm2home

ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/home/site/wwwroot

WORKDIR /home/site/wwwroot

ENTRYPOINT ["/opt/startup/init_container.sh"]
