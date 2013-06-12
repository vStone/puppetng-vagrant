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

## Augeas lenses?
[ -d /var/lib/puppet/lib/augeas/lenses ] || mkdir -pv /var/lib/puppet/lib/augeas/lenses
find /vagrant/${sources} -iname *.aug -exec cp -v {} /var/lib/puppet/lib/augeas/lenses/ \;

## Facts?
[ -d /var/lib/puppet/lib/facter ] || mkdir -pv /var/lib/puppet/lib/facter
find /vagrant/${sources} -iwholename */facter/* -iname *.rb -and -not -iname *spec.rb -exec cp -v {} /var/lib/puppet/lib/facter/ \;

#[ -d /var/lib/puppet/lib/puppet/parser/functions ] || mkdir -pv /var/lib/puppet/lib/puppet/parser/functions
#find /vagrant/${sources} -iwholename "*lib/puppet/parser/functions" -iname *.rb \
#  -exec cp -v {} /var/lib/puppet/lib/puppet/parser/functions/ \;

exec puppet apply \
  --environment ${environment} --pluginsync \
  --verbose --debug --trace \
  --graph --graphdir /vagrant/graphs/${boxname} \
  --modulepath '$confdir/environments/$environment/modules/internal:$confdir/environments/$environment/modules/upstream:$confdir/environments/$environment/modules/dev' \
  /etc/puppet/environments/${environment}/manifests/site.pp
