#!/bin/bash
set -eo pipefail
if [ -v DEBUG ]; then set -x; fi

# This section runs before supervisor and is good for initialization or pre-startup tasks
if [ "$2" = "foreground" ]; then
  # Set JAVA_ARGS options
  [ -n "${JAVA_ARGS}" ] && sed -i "s/JAVA_ARGS=.*$/JAVA_ARGS=\"\$JAVA_ARGS\"/" /etc/sysconfig/puppetdb


  # Set puppet.conf settings
  [ -n "${CERTNAME}" ] && puppet config set certname ${CERTNAME} --section agent --environment puppet
  [ -n "${AGENT_ENVIRONMENT}" ] && puppet config set environment ${AGENT_ENVIRONMENT} --section agent --environment puppet
  [ -n "${PUPPET_SERVER}" ] && puppet config set server ${PUPPET_SERVER} --section agent --environment puppet
  [ -n "${MASTERPORT}" ] && puppet config set masterport ${MASTERPORT} --section agent --environment puppet
  [ -n "${DNS_ALT_NAMES}" ] && puppet config set dns_alt_names ${DNS_ALT_NAMES} --section main  --environment puppet
  [ ! -n "${PUPPET_SERVER}" ] && PUPPET_SERVER=$(puppet config print server)
  [ ! -n "${MASTERPORT}" ] && MASTERPORT=$(puppet config print masterport)

  if [ -n "${CA_SERVER}" ]; then
    puppet config set ca_server ${CA_SERVER} --section main  --environment puppet
  else
    CA_SERVER=$(puppet config print ca_server)
  fi

  if [ -n "${CA_PORT}" ]; then
    puppet config set ca_port ${CA_PORT} --section main  --environment puppet
  else
    CA_PORT=$(puppet config print ca_port)
  fi


  puppet config set --section main dns_alt_names $(facter fqdn),$(facter hostname),$DNS_ALT_NAMES

  # Set database settings
  if [ -n "${PUPPETDB_DATABASE_SERVER}" ]; then
    echo "[database]" >/etc/puppetlabs/puppetdb/conf.d/database.ini
    echo "subname = //${PUPPETDB_DATABASE_SERVER}:${PUPPETDB_DATABASE_PORT}/${PUPPETDB_DATABASE_NAME}" >>/etc/puppetlabs/puppetdb/conf.d/database.ini
    echo "username = ${PUPPETDB_DATABASE_USER}" >>/etc/puppetlabs/puppetdb/conf.d/database.ini
    echo "password = ${PUPPETDB_DATABASE_PASSWORD}" >>/etc/puppetlabs/puppetdb/conf.d/database.ini
  fi

  # Make performance dashboard visible on 8080
  sed -i "s/^# host =.*/host = 0\.0\.0\.0/" /etc/puppetlabs/puppetdb/conf.d/jetty.ini

  ## Setup SSL and get certificate signed by puppet master if it isn't setup up
  ##   already (i.e. new container)
  if [ ! -d  /etc/puppetlabs/puppetdb/ssl ]; then
    while ! $(echo > /dev/tcp/${CA_SERVER}/${CA_PORT}) >/dev/null 2>&1; do
      echo 'Waiting for puppet server to become available...'
      sleep 10
    done

    # get our host certificate signed
    puppet agent \
        --verbose \
        --no-daemonize \
        --onetime \
        --noop \
        --server ${CA_SERVER} \
        --masterport ${CA_PORT} \
        --environment production \
        --waitforcert 30s

    ## Ensure puppetdb SSL certs are in sync with puppet agent signed SSL certs
    puppetdb ssl-setup -f
  fi
  echo 'Starting puppetdb...'
fi

## Pass control on to the command supplied on the CMD line of the Dockerfile
## This makes init PID 1
exec "$@"
