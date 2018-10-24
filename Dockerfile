FROM centos:7

LABEL maintainer="dskadra@gmail.com"

ENV PATH="$PATH:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/server/bin"
ENV FACTER_CONTAINER_ROLE="puppetdb"

## Current available releases: puppet5, puppet5-nightly, puppet6, puppet6-nightly
ENV PUPPET_RELEASE="puppet6"

## Latest by default, un-comment to pin specific versions or supply with -e PUPPETDB_VERSION
## Example:
## ENV PUPPETDB_VERSION="5.2.*"
## ENV PUPPETDB_VERSION="5.2.4"
ENV PUPPETDB_VERSION=
ENV DUMB_INIT_VERSION=1.2.2

RUN set -eo pipefail && if [[ -v DEBUG ]]; then set -x; fi && \
  # Import repository keys and add puppet repository
  rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7 \
  --import https://yum.puppet.com/RPM-GPG-KEY-puppet && \
  rpm -Uvh https://yum.puppet.com/${PUPPET_RELEASE}/${PUPPET_RELEASE}-release-el-7.noarch.rpm && \
  \
  # Update and install stuff
  yum -y update && \
  yum -y install \
    puppetdb${PUPPETDB_VERSION:+-}${PUPPETDB_VERSION} && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  \
  # Install dumb-init
  curl -Lo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64 && \
  chmod +x /usr/local/bin/dumb-init

  # Fix forground command so it can listen for signals from docker
  # sed -i "s/runuser \"/exec runuser \"/" \
  #   /opt/puppetlabs/server/apps/puppetdb/cli/apps/foreground


COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY logback.xml /etc/puppetlabs/puppetdb/
COPY request-logging.xml /etc/puppetlabs/puppetdb/


RUN chmod +x /docker-entrypoint.sh


    # puppet agent -v -w 30s \
    #   --environment ${ENVIRONMENT} \
    #   --server ${PUPPET_SERVER} \
    #   --no-daemonize \
    #   --no-usecacheonfailure \
    #   --onetime \
    #   --certname build-${HOSTNAME} && \
    # \
    # # Clean up puppet cache from build process
    # rm -rf /opt/puppetlabs/puppet/cache/* && \
    # \
    # # Clean build SSL keys.
    # rm -rf /etc/puppetlabs/puppet/ssl && \
    # rm -rf /etc/puppetlabs/puppetdb/ssl && \
    # \
    # # Clean tmp
    # find /tmp -mindepth 1 -delete && \
    # \
    # # Fix forground command so it can listen for signals from docker
    # sed -i "s/runuser \"/exec runuser \"/" \
    #   /opt/puppetlabs/server/apps/puppetdb/cli/apps/foreground


# VOLUME [ "/etc/puppetlabs", \
#         "/opt/puppetlabs/puppet/cache", \
#         "/opt/puppetlabs/server/data", \
#         "/var/log/puppetlabs" ]

ENV PUPPETDB_DATABASE_NAME="puppetdb"
ENV PUPPETDB_DATABASE_SERVER="postgres"
ENV PUPPETDB_DATABASE_PORT="5432"
ENV PUPPETDB_DATABASE_USER="puppetdb"
ENV PUPPETDB_DATABASE_PASSWORD="puppetdb"
ENV PUPPETDB_JAVA_ARGS="-Xmx192m"

VOLUME ["/etc/puppetlabs/puppet/ssl/"]

EXPOSE 8080 8081

ENTRYPOINT ["dumb-init", "/docker-entrypoint.sh"]
CMD ["puppetdb", "foreground"]