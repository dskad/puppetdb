FROM puppetagent

MAINTAINER Dan Skadra <dskadra@gmail.com>

RUN rm -rf /etc/puppetlabs/puppetdb/ssl
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

VOLUME [ "/etc/puppetlabs", \
        "/opt/puppetlabs/puppet/cache", \
        "/opt/puppetlabs/server/data", \
        "/var/log/puppetlabs", ]


EXPOSE 8080
EXPOSE 8081
EXPOSE 443
