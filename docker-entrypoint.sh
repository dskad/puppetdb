#!/bin/bash
## unofficial "strict mode" http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -eo pipefail
if [ -v DEBUG ]; then
  set -x
fi

# This section runs before supervisor and is good for initialization or pre-startup tasks
if [ $1 = "puppetdb" ]; then
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
