node 'puppet.localdomain' {

  host { 'puppet.localdomain':
    ip           => '192.168.5.2',
    host_aliases => 'puppet',
  }

  host { 'katello.localdomain':
    ip           => '192.168.5.3',
    host_aliases => 'katello',
  }

  unless $::operatingsystem in ['redhat', 'centos'] and Integer($::operatingsystemmajrelease) >= 6 {
    fail("'Your plattform ${::operatingsystem} is not supported.'")
  }

  yumrepo { 'puppet5':
    baseurl  => "http://yum.puppet.com/puppet5/el/${::operatingsystemmajrelease}/\$basearch",
    descr    => 'Puppet 5 Repository el 7 - $basearch',
    enabled  => 1,
    gpgcheck => 1,
    gpgkey   => 'http://yum.puppet.com/RPM-GPG-KEY-puppet',
  }

  Yumrepo['puppet5'] -> Package<||>

  include ::profile::puppet::master
}


node default {

  host { 'puppet.localdomain':
    ip           => '192.168.5.2',
    host_aliases => 'puppet',
  }

  host { 'katello.localdomain':
    ip           => '192.168.5.3',
    host_aliases => 'katello',
  }

  case $::operatingsystem {
    'centos': {
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
    } # CentOS

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
