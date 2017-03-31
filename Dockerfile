FROM puppetagent

ENV FACTER_CONTAINER_ROLE="puppetdb" \
    DNS_ALT_NAMES=puppet,puppet.example.com

ARG PUPPET_SERVER="puppet"
ARG ENVIRONMENT="puppet"
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh && \
    puppet agent -v -w 30s \
      --environment ${ENVIRONMENT} \
      --server ${PUPPET_SERVER} \
      --onetime \
      --no-daemonize \
      --no-usecacheonfailure \
      --no-splay \
      --show_diff \
      --no-use_cached_catalog

VOLUME [ "/etc/puppetlabs", \
        "/opt/puppetlabs/puppet/cache", \
        "/opt/puppetlabs/server/data", \
        "/var/log/puppetlabs" ]


EXPOSE 8080
EXPOSE 8081

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["puppetdb", "foreground"]