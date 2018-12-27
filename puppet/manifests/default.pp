node 'puppet.localdomain' {

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


node 'katello.localdomain' {
  host { 'puppet.localdomain':
    ip           => '192.168.5.2',
    host_aliases => 'puppet',
  }
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

  case $::osfamily {
    'redhat': {
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
    } # redhat
  }

  if $::kernel != 'windows' and $::shared_folders {
    if member(values($::shared_folders), '/etc/puppetlabs/code/environments/production') {
      file { '/root/puppetcode':
        ensure => link,
        target => '/etc/puppetlabs/code/environments/production',
      }
    }
  }

}
