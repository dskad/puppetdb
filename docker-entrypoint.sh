#!/bin/bash
## unofficial "strict mode" http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eo pipefail
if [ -v DEBUG ]; then
  set -x
fi

# This section runs before supervisor and is good for initalization or pre-startup tasks
if [ $1 = "puppetdb" ]; then
  ## Set puppet.conf settings
#  puppet config set server ${PUPPETSERVER} --section main --environment production
#  puppet config set environment ${PUPPETENV} --section main --environment production
#  puppet config set runinterval ${RUNINTERVAL} --section agent --environment production
#  puppet config set waitforcert ${WAITFORCERT} --section agent --environment production
#  puppet config set trusted_server_facts true --section main --environment production
#  if [ -v DNSALTNAMES ]; then
#    puppet config set dns_alt_names ${DNSALTNAMES} --section main  --environment production
#  fi

  ## Setup SSL and get certificate signed by puppet master if it isn't setup up
  ##   already (i.e. new container)
  if [ ! -d  /etc/puppetlabs/puppet/ssl ]; then
    ## Puppet service isn't running yet, so only setup SSL now to prevent any errors
    puppet agent --verbose --no-daemonize --onetime --noop

    ## Ensure puppetdb SSL certs are in sync with puppet agent signed SSL certs
    puppetdb ssl-setup -f
  fi
fi

## Pass control on to the command suppled on the CMD line of the Dockerfile
## This makes init PID 1
exec "$@"
