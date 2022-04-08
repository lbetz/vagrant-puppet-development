node default {

  host { 'nps-puppet.novalocal':
    ip           => '10.77.16.2',
    host_aliases => 'nps-puppet',
  }

  case $::operatingsystem {
    'centos', 'redhat', 'rockylinux', 'almalinux', 'oraclelinux': {
      if $::networking['interfaces']['eth1']['dhcp'] {
        network::interface { 'eth0':
          enable_dhcp => true,
          peerdns     => 'no',
        }

        network::interface { 'eth1':
          enable_dhcp   => true,
          dhcp_hostname => $::hostname,
        }
      } # dhcp (eth1)
    } # Enterprise Linux

    'fedora': {
      if $::networking['interfaces']['enp0s6']['dhcp'] {
        network::interface { 'enp0s5':
          enable_dhcp => true,
          peerdns     => 'no',
        }

        network::interface { 'enp0s6':
          enable_dhcp   => true,
          dhcp_hostname => $::hostname,
        }
      } # dhcp (enp0s6)
    } # Fedora
  }

  if $::kernel != 'windows' and $::shared_folders {
    if member(values($::shared_folders), '/etc/puppetlabs/code/environments/production') {
      file { '/root/puppetcode':
        ensure => link,
        target => '/etc/puppetlabs/code/environments/production',
      }
    } else {
      file { '/etc/puppetlabs/code/environments/production':
        ensure => link,
        target => '/root/puppetcode',
        force  => true,
      }
    }
  }

}
