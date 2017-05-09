#!/bin/bash
## unofficial "strict mode" http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eo pipefail
if [ -v DEBUG ]; then
  set -x
fi

# This section runs before supervisor and is good for initialization or pre-startup tasks
if [ $1 = "puppetdb" ]; then
  # Set puppet.conf settings
  [ -v PUPPET_SERVER ] && puppet config set server ${PUPPET_SERVER} --section main --environment puppet
  [ -v PUPPET_ENV ] && puppet config set environment ${PUPPET_ENV} --section main --environment puppet
  [ -v DNS_ALT_NAMES ] && puppet config set dns_alt_names ${DNS_ALT_NAMES} --section main  --environment puppet
  [ -v CA_SERVER ] && puppet config set ca_server ${CA_SERVER} --section main  --environment puppet

  ## Setup SSL and get certificate signed by puppet master if it isn't setup up
  ##   already (i.e. new container)
  if [ ! -d  /etc/puppetlabs/puppetdb/ssl ]; then
    # Ensure container configuration is up to date
    # Note: DNS_ALT_NAMES are set at image build because puppet signs cert on 1st connect
    puppet agent \
        --verbose \
        --no-daemonize \
        --onetime \
        --waitforcert 30s

    ## Ensure puppetdb SSL certs are in sync with puppet agent signed SSL certs
    puppetdb ssl-setup -f
  fi
fi

## Pass control on to the command supplied on the CMD line of the Dockerfile
## This makes init PID 1
exec "$@"
