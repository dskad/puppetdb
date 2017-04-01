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
      --no-daemonize \
      --no-usecacheonfailure \
      --certname build-`date +%s | sha256sum | head -c 8; echo ` && \

    # Clean up puppet cache from build process
    rm -rf /opt/puppetlabs/puppet/cache/* && \

    # Clean build SSL keys.
    rm -rf /etc/puppetlabs/puppetdb/ssl/* && \
    rm -rf /etc/puppetlabs/puppet/ssl/* && \

    # Clean tmp
    find /tmp -mindepth 1 -delete


VOLUME [ "/etc/puppetlabs", \
        "/opt/puppetlabs/puppet/cache", \
        "/opt/puppetlabs/server/data", \
        "/var/log/puppetlabs" ]


EXPOSE 8080
EXPOSE 8081

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["puppetdb", "foreground"]