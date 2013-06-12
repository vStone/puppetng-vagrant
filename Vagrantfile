#!/usr/bin/env ruby
# Shebang is here only for automatic syntax highlighting purposes.
# Do not try and run this file :)

Vagrant.require_plugin 'vagrant-hostmanager'

domain       = 'virtual.vstone.org'
puppetmaster = "puppetmaster.#{domain}"

VIRTUAL_MACHINES = {
  :puppetca     => {
    :ip             => '192.168.127.10',
    :hostname       => "puppetca01.#{domain}",
    :sourcedir      => 'puppetca',
  },
  :puppetmaster => {
    :ip             => '192.168.127.20',
    :hostname       => "puppetmaster01.#{domain}",
    :sourcedir      => 'puppet',
  },
  :puppetdb     => {
    :ip             => '192.168.127.30',
    :hostname       => "puppetdb01.#{domain}",
  },
  :proxy        => {
    :ip             => '192.168.127.40',
    :hostname       => "proxy01.#{domain}",
    :hostaliases    => [ puppetmaster ],
  },
  :foreman      => {
    :ip             => '192.168.127.50',
    :hostname       => "foreman01.#{domain}",
    :forwards       => {
      80  => 40080,
      443 => 40443,
    },
  },
  :test         => {
    :ip             => '192.168.127.40',
    :hostname       => "test01.#{domain}",
    :puppet         => :agent,
  },
}

Vagrant.configure('2') do |config|
  ## Hostmanager configuration
  config.hostmanager.enabled = false
  config.hostmanager.ignore_private_ip = false
  config.hostmanager.include_offline = true

  ## The base box we will use for ALl the hosts :)
  config.vm.box = "centos-6.x-64bit-puppet.3.x"
  config.vm.box_url = "http://packages.vstone.eu/vagrant-boxes/centos-6.x-64bit-latest.box"

  VIRTUAL_MACHINES.each do |name,cfg|
    config.vm.define name do |vm_config|

      ## Configure basics.
      vm_config.vm.box                = cfg[:box]           if cfg[:box]
      vm_config.vm.box_url            = cfg[:box_url]       if cfg[:box_url]
      vm_config.vm.hostname           = cfg[:hostname]      if cfg[:hostname]
      vm_config.hostmanager.aliases   = cfg[:hostaliases]   if cfg[:hostaliases]
      vm_config.vm.network :private_network, ip: cfg[:ip]   if cfg[:ip]

      if cfg[:forwards]
        cfg[:forwards].each do |guest, host|
          vm_config.vm.network :forwarded_port, guest: guest, host: host
        end
      end

      ## Deal with virtualbox options (setting memory and such)
      vm_config.vm.provider :virtualbox do |vbox|
        customize = ['modifyvm', :id] + (cfg[:virtualbox] || [])
        ## Customize the box name in Virtualbox.
        customize += ['--name', File.basename(File.dirname(__FILE__)) + "-#{name}_#{Time.now.to_i}"] unless customize.include?('--name')
        vbox.customize customize
      end

      environment = cfg[:environment] || 'infrastructure'
      sourcedir   = cfg[:sourcedir] || 'puppet'

      ## Update hosts file on the machine.
      vm_config.vm.provision :hostmanager

      if File.exists?(File.expand_path(File.join(File.dirname(__FILE__), "./scripts/pre-#{name}.sh")))
        vm_config.vm.provision :shell do |shell|
          shell.path = File.expand_path(File.join(File.dirname(__FILE__), "./scripts/pre-#{name}.sh"))
          shell.args = "#{environment} #{sourcedir}"
        end
      end

      if cfg[:puppet] and [:agent, :client].include?(cfg[:puppet])
        vm_config.vm.provision :puppet_server do |puppet|
          puppet.puppet_server = puppetmaster
          puppet.options = "--verbose --debug --environment #{environment} --test"
        end
      else
        vm_config.vm.provision :shell do |shell|
          if File.exists?(File.expand_path(File.join(File.dirname(__FILE__), "./scripts/puppetrun-#{name}.sh")))
            shell.path = "scripts/puppetrun-#{name}.sh"
          else
            shell.path = "scripts/puppetrun.sh"
          end
          shell.args = "#{environment} #{name} #{sourcedir}"
        end
      end

    end
  end

end
