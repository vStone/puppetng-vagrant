#!/bin/bash
#
environment=${1-production}
boxname=${2-unknown}
sources=${3-puppet}

## Make sure the required directories exist.
[ -d /etc/puppet/environments/${environment} ] || mkdir -p /etc/puppet/environments/${environment}
[ -d /etc/puppet/hieradata ] || mkdir -p /etc/puppet/hieradata
[ -d /vagrant/graphs/${boxname} ] || mkdir -p /vagrant/graphs/${boxname}

## Copy general config files.
[ -f /vagrant/${sources}/hiera.yaml-base ] && cp /vagrant/${sources}/hiera.yaml-base /etc/puppet/hiera.yaml
[ -f /vagrant/${sources}/puppet.conf-base ] && cp /vagrant/${sources}/puppet.conf-base /etc/puppet/puppet.conf

## Sync puppet code to the right environment.
rsync -alrcWt --del --progress \
  --exclude=.git --exclude=.svn --exclude=*.swp \
  --exclude=vendor/ --exclude=.vendor/ \
  /vagrant/${sources}/* /etc/puppet/environments/${environment}/


## Sync hieradata code.
if [ -d /vagrant/hieradata ]; then
  rsync -alrcWt --del --progress \
    --exclude=.git --exclude=.svn \
    /vagrant/hieradata/ /etc/puppet/hieradata/
fi;

exec puppet apply \
  --environment ${environment} \
  --verbose --debug --trace \
  --graph --graphdir /vagrant/graphs/${boxname} \
  --modulepath '$confdir/environments/$environment/modules/internal:$confdir/environments/$environment/modules/upstream' \
  /etc/puppet/environments/${environment}/manifests/site.pp
