FROM centos:7

LABEL maintainer="dskadra@gmail.com"

ENV PATH="$PATH:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/server/bin"
ENV FACTER_CONTAINER_ROLE="puppetdb"

## Current available releases: puppet5, puppet5-nightly, puppet6-nightly
ENV PUPPET_RELEASE="puppet5"

## Latest by default, un-comment to pin specific versions or supply with -e PUPPETDB_VERSION
## Example:
## ENV PUPPETDB_VERSION="5.2.*"
## ENV PUPPETDB_VERSION="5.2.4"
ENV PUPPETDB_VERSION=

RUN set -eo pipefail && if [[ -v DEBUG ]]; then set -x; fi && \
  # Import repository keys and add puppet repository
  rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7 \
  --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet && \
  rpm -Uvh https://yum.puppetlabs.com/${PUPPET_RELEASE}/${PUPPET_RELEASE}-release-el-7.noarch.rpm && \
  \
  # Update and install stuff
  yum -y update && \
  yum -y install \
    puppetdb${PUPPETDB_VERSION:+-}${PUPPETDB_VERSION} && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  \
 # Fix forground command so it can listen for signals from docker
  sed -i "s/runuser \"/exec runuser \"/" \
    /opt/puppetlabs/server/apps/puppetdb/cli/apps/foreground














ARG PUPPET_SERVER="puppet"
ARG ENVIRONMENT="puppet"
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh && \
    puppet agent -v -w 30s \
      --environment ${ENVIRONMENT} \
      --server ${PUPPET_SERVER} \
      --no-daemonize \
      --no-usecacheonfailure \
      --onetime \
      --certname build-${HOSTNAME} && \
    \
    # Clean up puppet cache from build process
    rm -rf /opt/puppetlabs/puppet/cache/* && \
    \
    # Clean build SSL keys.
    rm -rf /etc/puppetlabs/puppet/ssl && \
    rm -rf /etc/puppetlabs/puppetdb/ssl && \
    \
    # Clean tmp
    find /tmp -mindepth 1 -delete && \
    \
    # Fix forground command so it can listen for signals from docker
    sed -i "s/runuser \"/exec runuser \"/" \
      /opt/puppetlabs/server/apps/puppetdb/cli/apps/foreground


# VOLUME [ "/etc/puppetlabs", \
#         "/opt/puppetlabs/puppet/cache", \
#         "/opt/puppetlabs/server/data", \
#         "/var/log/puppetlabs" ]


EXPOSE 8080
EXPOSE 8081

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["puppetdb", "foreground"]