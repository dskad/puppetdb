#!/usr/bin/env bash
set -e

certname=$(puppet config print certname) && \
curl -sS --fail -H 'Accept: pson' \
  --resolve "${certname}:8081:127.0.0.1" \
  --cert   /etc/puppetlabs/puppet/ssl/certs/${certname}.pem \
  --key    /etc/puppetlabs/puppet/ssl/private_keys/${certname}.pem \
  --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem \
  https://${certname}:8081/status/v1/services/puppetdb-status | \
  grep -q '"state":"running"' || \
  exit 1
