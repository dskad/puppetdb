#!/bin/bash
## unoficial "strict mode" http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eo pipefail
if [ -v DEBUG ]; then
  set -x
fi

# This section runs before supervisor and is good for initalization or pre-startup tasks
if [ $1 = "/usr/sbin/init" ]; then
  ## Create /var/run/puppetlabs directory as this will go missing since we are mounting tmpfs here
  ## Puppetserver startup doesn't recreate this directory
  ## https://tickets.puppetlabs.com/browse/SERVER-441
  mkdir -p /run/puppetlabs

  ## Only initalize and setup the environments (via r10k) if server is launching
  ##    for the first time (i.e. new server container). We don't want to unintentionally
  ##    upgrade an environment or break certs on a container restart or upgrade.
  if [ ! -d  /etc/puppetlabs/puppet/ssl ]; then
    # Apply inital config on startup.
    puppet agent --verbose --no-daemonize --onetime --noop \
            --environment=${PUPPETENV} \
            --server=${PUPPETSERVER} \
            --waitforcert=${WAITFORCERT}

    # /opt/puppetlabs/bin/puppetdb ssl-setup -f
    puppetdb ssl-setup -f
  fi

  ## Set puppet.conf settings
  puppet config set runinterval ${RUNINTERVAL} --section agent --environment production
  puppet config set waitforcert ${WAITFORCERT} --section agent --environment production
  puppet config set server ${PUPPETSERVER} --section main --environment production
  puppet config set trusted_server_facts true --section main --environment production
  if [ -v DNSALTNAMES ]; then
    puppet config set dns_alt_names ${DNSALTNAMES} --section main  --environment production
  fi
  puppet config set environment ${PUPPETENV} --section main --environment production
fi

## Pass control on to the command suppled on the CMD line of the Dockerfile
## This makes init PID 1
exec "$@"
