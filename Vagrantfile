# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
VAGRANT_REQUIRED_LINKED_CLONE_VERSION = "1.8.0"

require 'yaml'


# Provisioning module
module Vagrant
  module Config
    module V2
      class Root
        def provision(facter, os)
          case os[:family]
          when "redhat"
            vm.provision :shell, :path => 'scripts/redhat.sh', :args => [ os[:name], os[:release] ]
          when "debian"
            vm.provision :shell, :path => 'scripts/debian.sh', :args => [ os[:name], os[:release] ]
          when "suse"
            vm.provision :shell, :path => 'scripts/suse.sh', :args => [ os[:name], os[:release] ]
          when "windows"
            vm.provision :shell, :path => 'scripts/windows.ps1' 
          end
          vm.provision :puppet do |puppet|
            if os[:family] == "windows"
              puppet.environment_path = "puppet/environments.windows"
            else
              puppet.binary_path = "/opt/puppetlabs/bin"
              puppet.environment_path = "puppet/environments"
            end
            puppet.hiera_config_path = "puppet/hiera.yaml"
            puppet.structured_facts = true
            puppet.facter = facter
          end
        end
      end
    end
  end
end


# Load configuration, machines and networks
ConfigValues = YAML.load_file(File.dirname(File.expand_path(__FILE__)) + "/config.yaml")


Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vbguest.auto_update = false if Vagrant.has_plugin?("vagrant-vbguest")

  ConfigValues['machines'].each_pair do |name, options|
    # defaults
    options[:memory] = 512 unless options[:memory]
    options[:cpu] = 1 unless options[:cpu]
    options[:domain] = options[:net].keys.first unless options[:domain]
    options[:facts] = {} unless options[:facts]
    options[:facts]['shared_folders'] = false unless options[:shared]

    unless ConfigValues['operatingsystems'][options[:os]]
      puts "#{options[:os]} is not supported."
      exit 1
    end
    options[:os] = ConfigValues['operatingsystems'][options[:os]]

    config.vm.define name do |node|
      # base boxes
      node.vm.box = options[:os][:box]
      if options[:os][:family] == "windows"
        node.vm.communicator = "winrm"
        node.ssh.insert_key = true
      else
        node.ssh.forward_agent = true
        node.ssh.insert_key = true
        node.vm.synced_folder ".", "/vagrant"
      end

      node.vm.hostname = name
      node.vm.host_name = name + "." + options[:domain] if options[:os][:family] != "windows"

      if options[:forwarded]
        options[:forwarded].each_pair do |guest, local|
          node.vm.network "forwarded_port", guest: guest, host: local
        end
      end

      if options[:shared]
        options[:facts]['shared_folders'] = options[:shared]
        options[:shared].each_pair do |remote, local|
          node.vm.synced_folder remote, local
        end
      end

      node.provision( {'domain' => options[:domain], 'fqdn' => name + "." + options[:domain]}.merge(options[:facts]), options[:os] )

      node.vm.provider :parallels do |prl, override|
        prl.name = name
        prl.linked_clone = true
        prl.check_guest_tools = true
        prl.update_guest_tools = true if options[:os][:family] == "windows"

        i=0 # create internal network intrfaces
        prl_customize = []
        options[:net].each_pair do |nic, attrs| i=i+1
          prl_customize.concat([ "net#{i}", "--mac", "#{attrs[:mac]}" ]) if attrs[:mac]
          if attrs[:ip]
            override.vm.network :private_network, ip: attrs[:ip]
          else
            override.vm.network :private_network, ip: ConfigValues['networks'][nic][:address], type: "dhcp"
          end
        end
#        override.vm.network "public_network", bridge: "en0"

        prl.customize [ "set", :id, "--device-set" ].concat(prl_customize) unless prl_customize.empty?
        prl.memory = options[:memory]
        prl.cpus = options[:cpu]
      end

      node.vm.provider :virtualbox do |vb, override|
        vb.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new(VAGRANT_REQUIRED_LINKED_CLONE_VERSION)
        vb.name = name
        vb.gui = false

        i=1 # create internal network interfaces
        vb_customize = []
        options[:net].each_pair do |nic, attrs| i=i+1
          vb_customize.concat([ "--nic#{i}", "intnet", "--intnet#{i}", nic ]) if ConfigValues['networks'][nic][:type] == 'internal'
          vb_customize.concat([ "--macaddress#{i}", "#{attrs[:mac]}" ]) if attrs[:mac]
          if attrs[:ip]
            override.vm.network :private_network, :adapter => i, ip: attrs[:ip]
            override.vm.network :private_network, :adapter => i, ip: attrs[:ip], virtualbox__intnet: nic if ConfigValues['networks'][nic][:type] == 'internal'
          else
            override.vm.network :private_network, :adapter => i, type: "dhcp"
            override.vm.network :private_network, :adapter => i, type: "dhcp", virtualbox__intnet: nic if ConfigValues['networks'][nic][:type] == 'internal'
          end
        end

        vb.customize ["modifyvm", :id,
          "--groups", "/Training/Icinga 2 Fundamentals",
          "--audio", "none",
          "--usb", "on",
          "--usbehci", "off",
        ].concat(vb_customize)
        vb.memory = options[:memory] 
        vb.cpus = options[:cpu] 
      end

    end

  end
end
