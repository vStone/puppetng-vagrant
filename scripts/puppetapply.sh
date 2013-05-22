#!/bin/bash
#
environment=${1-production}
boxname=${2-unknown}
sources=${3-puppet}

## Puppet setup.
[ -d /etc/puppet/environments/${environment} ] || mkdir -pv /etc/puppet/environments/${environment}
[ -d /vagrant/graphs/${boxname} ] || mkdir -pv /vagrant/graphs/${boxname}
[ -f /vagrant/${sources}/puppet.conf-base ] && cp -v /vagrant/${sources}/puppet.conf-base /etc/puppet/puppet.conf
# Sync puppet code to the right environment.
rsync -alrcWt --del --progress \
  --exclude=.git --exclude=.svn --exclude=*.swp \
  --exclude=vendor/ --exclude=.vendor/ \
  /vagrant/${sources}/* /etc/puppet/environments/${environment}/

## Hiera setup
[ -f /vagrant/${sources}/hiera.yaml ] && cp -v /vagrant/${sources}/hiera.yaml /etc/puppet/hiera.yaml  || \
  ( [ -f /vagrant/${sources}/hiera.yaml-base ] && cp -v /vagrant/${sources}/hiera.yaml-base /etc/puppet/hiera.yaml )

hiera_sync_to=/etc/puppet/hieradata
## If we include the environment in the datadir setting, add it to the path.
#  Only works where the exact path is /etc/puppet/hieradata/environment ofcourse.
[ -f /etc/puppet/hiera.yaml ] && grep -q ':datadir:.*%{environment}' /etc/puppet/hiera.yaml && hiera_sync_to=/etc/puppet/hieradata/${environment}
[ -d $hiera_sync_to ] || mkdir -pv $hiera_sync_to

## Sync hieradata code.
if [ -d /vagrant/hieradata ]; then
  rsync -alrcWt --del --progress \
    --exclude=.git --exclude=.svn \
    /vagrant/hieradata/ $hiera_sync_to
fi;

exec puppet apply \
  --environment ${environment} \
  --verbose --debug --trace \
  --graph --graphdir /vagrant/graphs/${boxname} \
  --modulepath '$confdir/environments/$environment/modules/internal:$confdir/environments/$environment/modules/upstream' \
  /etc/puppet/environments/${environment}/manifests/site.pp
