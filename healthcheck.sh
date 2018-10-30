#!/usr/bin/env bash
set -e

hostname=$(puppet config print certname) && \
curl -sS --fail -H 'Accept: pson' \
  --resolve "${hostname}:8081:127.0.0.1" \
  --cert   /etc/puppetlabs/puppet/ssl/certs/${hostname}.pem \
  --key    /etc/puppetlabs/puppet/ssl/private_keys/${hostname}.pem \
  --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem \
  https://${hostname}:8081/status/v1/services/puppetdb-status \
  | grep -q '"state":"running"' \
  || exit 1
