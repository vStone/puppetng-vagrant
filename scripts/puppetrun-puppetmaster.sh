#!/bin/bash
#
environment=${1-production}
boxname=${2-unknown}
sources=${3-puppet}

## Puppet setup.
[ -d /etc/puppet/environments/${environment} ] || mkdir -pv /etc/puppet/environments/${environment}/{manifests,modules}
[ -d /vagrant/graphs/${boxname} ] || mkdir -pv /vagrant/graphs/${boxname}
[ -f /vagrant/${sources}/puppet.conf-base ] && cp -v /vagrant/${sources}/puppet.conf-base /etc/puppet/puppet.conf

## Use bind mounts so we dont need to reprovision for getting new codes.
mount -o bind /vagrant/${sources}/manifests /etc/puppet/environments/${environment}/manifests
mount -o bind /vagrant/${sources}/modules /etc/puppet/environments/${environment}/modules

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
  ## Same, use bind mounts...
  mount -o bind /vagrant/hieradata $hiera_sync_to
fi;

domainname=$( hostname -d )
echo "*.$domainname" > /etc/puppet/autosign.conf
chmod 0664 /etc/puppet/autosign.conf
chown puppet:puppet /etc/puppet/autosign.conf

## Customize the puppet.conf using augeas
[ -f /vagrant/augeas/${boxname}.augeas ] && ( cat /vagrant/augeas/${boxname}.augeas | sed "s/DOMAIN/$domainname/g" |  augtool -b -A  )

screen -d -m puppet master --no-daemonize \
  --verbose --debug --trace
