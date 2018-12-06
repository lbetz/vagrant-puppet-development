class profile::puppet::master {

  #
  # Postgresql 9.4 from PuppetDB
  #

  class { 'puppetdb::database::postgresql':
    manage_package_repo => false,
    postgres_version    => '9.6',
    listen_addresses    => '*',
  }

  #
  # GitLab
  #

#  Class['puppetdb::database::postgresql']
#    -> Postgresql::Server::Role['gitlab']
#    -> Postgresql::Server::Database['gitlabhq_production']
#    -> Class['gitlab']
#
#  postgresql::server::role { 'gitlab':
#    password_hash => postgresql_password('gitlab', 'gitlab'),
#    superuser     => true,
#  }
#
#  postgresql::server::database { 'gitlabhq_production':
#    owner => 'gitlab'
#  }
#
#  class { '::gitlab':
#    external_url => 'http://localhost',
#    postgresql   => {
#      enable => false,
#    },
#    gitlab_rails => {
#      'db_adapter'  => 'postgresql',
#      'db_encoding' => 'utf8',
#      'db_host'     => '127.0.0.1',
#      'db_port'     => 5432,
#      'db_username' => 'gitlab',
#      'db_password' => 'gitlab',
#    },
#    unicorn => {
#      port => 8083,
#    }
#  }

  #
  # Puppetmaster / PuppetDB
  #

  Systemd::Unit_file['puppetmaster.service']
    -> Class['puppet']
  Service['puppetmaster']
    -> Class['puppetdb::server']
    -> Class['puppetdb::master::config']

  systemd::unit_file { 'puppetmaster.service':
   source => "puppet:///modules/profile/puppetmaster.service",
  }

  class { '::puppet':
    server                        => true,
    server_implementation         => 'master',
    server_package                => 'puppetserver',
    server_passenger              => false,
    server_service_fallback       => true,
    agent                         => true,
    vardir                        => '/opt/puppetlabs/server/data/puppetserver',
    server_common_modules_path    => '/etc/puppetlabs/code/modules',
    server_directory_environments => true,
    server_dynamic_environments   => false,
    server_environments           => [ 'production' ],
    show_diff                     => true,
    server_storeconfigs_backend   => 'puppetdb',
    server_reports                => 'store',
    server_foreman                => false,
    server_external_nodes         => '',
    server_environments_owner     => 'puppet',
    server_environments_group     => 'puppet',
    server_manage_user            => false,
  }

  class { '::puppetdb::server':
    manage_firewall   => false,
    java_args         => [ '-Xmx128m' ],
  }

  user { 'puppet':
    ensure  => present,
    shell   => '/bin/bash',
    require => Package['puppetserver'],
  }

  class { '::puppetdb::master::config':
    restart_puppet              => false,
    puppetdb_soft_write_failure => true,
    strict_validation           => false,
    enable_reports              => true,
  }

  #
  # R10K auto deployment
  #

#  Package['puppetserver']
#    -> File['/opt/puppetlabs/server/data/puppetserver']
#  File['/opt/puppetlabs/server/data/puppetserver/.ssh']
#    -> Sshkey['puppet.localdomain']
#
#  class { 'r10k':
#    sources => {
#      'puppet' => {
#        remote => 'git@puppet.localdomain:puppet/control.git',
#        basedir => '/etc/puppetlabs/code/environments',
#        prefix => false,
#      },
#    },
#    git_settings => {
#      private_key => '/opt/puppetlabs/server/data/puppetserver/.ssh/id_rsa',
#    },
#    cachedir     => '/opt/puppetlabs/server/data/puppetserver/r10k',
#  }
#
#  # private/public key pair user 'puppet'
#  file {
#    default:
#      ensure => directory,
#      owner  => 'puppet',
#      group  => 'puppet';
#    '/opt/puppetlabs/server/data/puppetserver':
#      mode   => '0755';
#    '/opt/puppetlabs/server/data/puppetserver/.ssh':
#      mode   => '0700';
#  }
#
#  file { '/opt/puppetlabs/server/data/puppetserver/.ssh/id_rsa':
#    ensure  => present,
#    owner   => 'puppet',
#    group   => 'puppet',
#    mode    => '0600',
#    content => '-----BEGIN RSA PRIVATE KEY-----
#MIIJJwIBAAKCAgEAx0SYXschy/ynM23VmAoU2U9cYY8G+ZgMJqMQvlui2lSOGBqk
#xUVsNugYZ2z0qkyO4aMWbA6rQmrpqThZJw/lE9IgmrxDMWCY7qgXsaNIcgSqkr+5
#B3QV79kPm4Dz2kOv5eg3kwrRbJLmnSdgIOEZH3kZE5V1EHIYuA1rLhyYP7A7fHm0
#UKSm+GNbcDNyGGehqmdwy7qRygSAGspL4Hof4Y8O+doZZd10/sHCkH4oqOWwagtt
#qlsHT6S5d1TGGB3r7qhwEBoz/kueZRSaRQEw1aIFrJMTrnsJk5OQ9xSeAzN2s53e
#DG130KTpn/GSUFBEfAoSv98eupKAIXpbICQZANQB2w+QDJ4ZajBq/DUCj1bHXrDW
#KOEBxR/HwQVCzVpwZ1TeEKDfCojZVluncKog6XxUNuEKen/NeANFgfslTS4BZv5f
#PSYy5icLFho6/KioISgJ9OWzc3lLFBS6ikbgsr+G7T+qHom8u5S2hOLUApYvQDdM
#SGhiB4+hPpUZ425dJFQ51o/5Qzokvx7V+PdgqCYPEWjwyQpo7PUFSm00w0YKhOa+
#FJJ0e82wdW9ygTZTcbKuUCYInREoaWlVZtJ57YoTUHc2nG9eWRNuMXPd6b7APKu5
#XNAS7R8KlhpWFTStnQY9I2l4CYtjAlQ0jsq0fz0Kb1ULCv2Eo1HsckQg42UCAwEA
#AQKCAgBwmbFkNTBC3YT5ycHdxSyc03yHYFP3rFSJbLGkb5GpwAf/VObw1lbc++/2
#WZoztUkz9X1RGETsJg/dYIr4SMIQnjdwWJu7hjNFANVKutLQIxTkEdSTgqR2wPhR
#zd994au+xabJv14x9Ry9hyeJzMjugPaLm3PoFCElt+dtyhi6PHKQ1xDuVOxJBZQA
#5gE+CylOal9RsB57wmlFOjUAJuJnCfjTdMvPRQG8h27TSYbeUdSLR+PzVLbf6Vwo
#M04xCI9ub93LK5Nfygk6Yxb9kTuwLHr6Vq3TdZEmxEcxZ4QWmPklbDqyWRVQYC/o
#ApDEM2dPlD2eEI2Drg8bW9Gsatl5H+K9xvcPJnDkk4RYE37mesqNIEoU4bfOC0ig
#FI9U7pVEtyaPO38UrPDDae0SrjBPBJ1nssa4KUiCC/YNQrlMppsdjXSBe6gVGzdM
#mmrW/1Y34oRBQm/Atl9x8SprIFab065KocTVBJXkWKl/CTDDNy4NhnVgh8hni3wv
#dWnUbcl6gLjBpIih4fWJRGjxvu4FZQNeFM+tNhb/n0zTp4UcGInOaZrISg2bZy2b
#3Tx+fBH61chVcPOdCKSh8GspvD96Tqh9rodAPRt9AQ+SeLWlys96jQcW/H7NVZZu
#ZWAlQBjNaqQ89WcVB8uWxkV2fA9rNfWMHTNRta3GoYwndGcETQKCAQEA6p9R/3Qr
#Fvy6BuP9NnNkZSe5iSOPIkdPd5Ew5uj/gl8OY5AjIw76iV0EcW54VB5gnd7x0Fj0
#XYyuBwrLRMMOD831XCT9h88W7tSt4DfT+ZR9Hfz8+wsS7GOUBiGFWTJbKNWlOhp0
#I2B08wq/DAaGHPEAGV/Uj6B2er+GPyPLvn37qgVydB6UEpq3TPz+AZnGpRADE6e8
#jbVBOTLmiZVxSbsV1E4XUIyztIBLLZ6Wt9ClDPYXtfmhh5Cku184Ha7b/R1GbQNM
#EM7DAPOIhxTtp7Wn2//jlaUOgCHkBhCibK1LuqmNkRAOwNQ68vpZfFD7aJNfthLM
#nVAl5uqClM7C4wKCAQEA2Wyd1LOroCZWlXv+aGvbigdkbpt0mqxxMp9g5zY6Ry6W
#GMnEXDUqz/pn+cXazYnUYmmneVJuu+7LZ/M6Nx25iV0z5hxBJvfZA0ysox4hLq2A
#2SfhnkPJ5Jr1xSPsDttu0gYbBrSb3ckqg3adpoaA1gDooejWVOON8aY3KPGGN7jG
#+PIvYhtNPrqD2UU53fNCLbMD2ig0xPPWRc+laamKOu07TLCcRcxJVXQVI8aMdMK/
#/B0xiW2OWUgrukQBUjdFIfXA4c2C7UF9+HSfEL6SFjBu2145oHoJiEyJYNOHXaJj
#8x3LdpASFMaTG0THjkNjt7Pp2feRG47bsuUPym3rFwKCAQB5e9ErYm1FU8rG8poT
#7Z/YOL964OymJSJimM0nYxGZ4bpDl0h6SLE1GvLIARlRBQGl/OBcrxKotcUOZGpn
#yk+no08eTRDxlysaswjtBjs+CcLXGj2rh0pfGBh3LDgtvUMyW51X/oaQIsurZK8T
#fPVIWwlgGhyn2cA/QpgybUh79COxH2zp70Ngdrfep0imb4dJxIazULDy9x00jsSM
#DNNCCBr/eQfdb11FYwCKOIl12BT+JxaT5RPca+rAEkeuJvJFlzj2DTT/pu+VuIPC
#3fVIV2j5IwAmZfaiJeo5sbdIalrB5jUlHZlmAv4a/cID+rKSrWxrjERiWDOn41mF
#z6FdAoIBABzPU6qXlCpIajiskW1svU5w5FHzr2O/bdBzZfe9K8O63JC0S5ycPuwI
#Fjb2jKOnm8jejx54Wcv1PGatyAz9l1QoUXQwUkHDnbHeOxHyMBtrSiN8MV0zRlFQ
#ZziUJfdiBDE4NeSRkgW1XjjFQuaJ9BBnVmv92kitTmWyzKRUPKCtj0/1Z2nsjDO/
#qzDjB2Ptk9tSWTRTF4rxdHcTqKtzl6lvPehPjqWBCEaWdyaibIIcPCxAAgxfw/j4
#ozKvSC2IvVReqAxDmxGtF/AQI/OoDNt713Sh66jkAtdYrOtznABAQFY6oHc5Z+vw
#1BVM69RiAZiZ8ma7czLfnyT5TTpZjkkCggEAGg9cpH8RSyrywxNHhpEsYSLQ65rt
#A8jYbs5eqs3HaLum/gGumHCi46IpKDNQLvYkeXVjhM+3+KIHVprk5HUUXxY8Jmbc
#X2RLZQFliY4/TH+QVCmIxU2tmKJTmWkn3povMPou0ES1jSkBHPXNhsSctSUy0ZJ0
#6GlUcq72N9GawPR0/uiMnDGijga+D/crWO5m8FyZLEtACFyGo8FyNLFPu5S3ihbM
#YESxgywr8wS9mRZP0/MCXBcxhe8gvbV09MUTeZO+dBNCFMYXgS3MkyGqJRg8VjKd
#2U4GTJ0mF+1KLzKBVpd13/lNgVube+cVPmXTnn6e68Dg0H1mcXZiab+Wrg==
#-----END RSA PRIVATE KEY-----
#',
#  }
#
#  file { '/opt/puppetlabs/server/data/puppetserver/.ssh/id_rsa.pub':
#    ensure  => present,
#    owner   => 'puppet',
#    group   => 'puppet',
#    mode    => '0644',
#    content => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHRJhexyHL/KczbdWYChTZT1xhjwb5mAwmoxC+W6LaVI4YGqTFRWw26BhnbPSqTI7hoxZsDqtCaumpOFknD+UT0iCavEMxYJjuqBexo0hyBKqSv7kHdBXv2Q+bgPPaQ6/l6DeTCtFskuadJ2Ag4RkfeRkTlXUQchi4DWsuHJg/sDt8ebRQpKb4Y1twM3IYZ6GqZ3DLupHKBIAaykvgeh/hjw752hll3XT+wcKQfiio5bBqC22qWwdPpLl3VMYYHevuqHAQGjP+S55lFJpFATDVogWskxOuewmTk5D3FJ4DM3aznd4MbXfQpOmf8ZJQUER8ChK/3x66koAhelsgJBkA1AHbD5AMnhlqMGr8NQKPVsdesNYo4QHFH8fBBULNWnBnVN4QoN8KiNlWW6dwqiDpfFQ24Qp6f814A0WB+yVNLgFm/l89JjLmJwsWGjr8qKghKAn05bNzeUsUFLqKRuCyv4btP6oeiby7lLaE4tQCli9AN0xIaGIHj6E+lRnjbl0kVDnWj/lDOiS/HtX492CoJg8RaPDJCmjs9QVKbTTDRgqE5r4UknR7zbB1b3KBNlNxsq5QJgidEShpaVVm0nntihNQdzacb15ZE24xc93pvsA8q7lc0BLtHwqWGlYVNK2dBj0jaXgJi2MCVDSOyrR/PQpvVQsK/YSjUexyRCDjZQ== puppet@master',
#  }
#
#  # add hostkey to known_hosts of user 'puppet'
#  sshkey { 'puppet.localdomain':
#    ensure => present,
#    type   => 'ssh-rsa',
#    target => '/opt/puppetlabs/server/data/puppetserver/.ssh/known_hosts',
#    key    => $::ssh['rsa']['key'],
#  }
#
#  # ssh public key for incomming ssh connects to deploy via r10k
#  ssh_authorized_key { 'puppet@master':
#    ensure  => present,
#    type    => 'rsa',
#    user    => 'puppet',
#    name    => 'puppet@master',
#    key     => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDHRJhexyHL/KczbdWYChTZT1xhjwb5mAwmoxC+W6LaVI4YGqTFRWw26BhnbPSqTI7hoxZsDqtCaumpOFknD+UT0iCavEMxYJjuqBexo0hyBKqSv7kHdBXv2Q+bgPPaQ6/l6DeTCtFskuadJ2Ag4RkfeRkTlXUQchi4DWsuHJg/sDt8ebRQpKb4Y1twM3IYZ6GqZ3DLupHKBIAaykvgeh/hjw752hll3XT+wcKQfiio5bBqC22qWwdPpLl3VMYYHevuqHAQGjP+S55lFJpFATDVogWskxOuewmTk5D3FJ4DM3aznd4MbXfQpOmf8ZJQUER8ChK/3x66koAhelsgJBkA1AHbD5AMnhlqMGr8NQKPVsdesNYo4QHFH8fBBULNWnBnVN4QoN8KiNlWW6dwqiDpfFQ24Qp6f814A0WB+yVNLgFm/l89JjLmJwsWGjr8qKghKAn05bNzeUsUFLqKRuCyv4btP6oeiby7lLaE4tQCli9AN0xIaGIHj6E+lRnjbl0kVDnWj/lDOiS/HtX492CoJg8RaPDJCmjs9QVKbTTDRgqE5r4UknR7zbB1b3KBNlNxsq5QJgidEShpaVVm0nntihNQdzacb15ZE24xc93pvsA8q7lc0BLtHwqWGlYVNK2dBj0jaXgJi2MCVDSOyrR/PQpvVQsK/YSjUexyRCDjZQ==',
#  }
#
#  #
#  # Webhook
#  #
#
#  Service['puppetmaster']
#    -> Class['r10k::webhook::config']
#    -> Class['r10k::webhook']
#
#  class { 'r10k::webhook::config':
#    hash => {
#      access_logfile        => '/var/log/webhook/access.log',
#      allow_uppercase       => true,
#      bind_address          => '0.0.0.0',
#      client_timeout        => '120',
#      command_prefix        => 'umask 0022;',
#      default_branch        => 'production',
#      discovery_timeout     => '10',
#      enable_mutex_lock     => false,
#      enable_ssl            => true,
#      public_key_path       => "/etc/puppetlabs/puppet/ssl/certs/${::trusted[certname]}.pem",
#      private_key_path      => "/etc/puppetlabs/puppet/ssl/private_keys/${::trusted[certname]}.pem",
#      protected             => true,
#      generate_types        => false,
#      ignore_environments   => [],
#      pass                  => 'topsecret',
#      port                  => 8088,
#      prefix                => false,
#      r10k_deploy_arguments => '-p',
#      server_software       => 'WebHook',
#      use_mco_ruby          => false,
#      use_mcollective       => false,
#      user                  => 'puppet',
#      servers               => 'puppet.localdomain',
#    },
#  }
#
#  class { 'r10k::webhook':
#    ensure       => true,
#  }
#
#  #
#  # Bind DNS
#  #
#  class { 'dns':
#    forwarders => [ '8.8.8.8', ],
#    zones      =>  {
#      'localdomain' => { soaip => $::ipaddress_eth1, },
#      '5.168.192.in-addr.arpa' => { reverse => true, },
#    },
#  }
#
#  #
#  # ISC DHCP
#  #
#  class { 'dhcp':
#    dnsdomain    => [ 'localdomain', '5.168.192.in-addr.arpa' ],
#    nameservers  => [ '192.168.5.100', ],
#    interfaces   => ['eth1'],
#    dnsupdatekey => '/etc/rndc.key',
#    pxeserver    => '192.168.5.100',
#    pxefilename  => 'pxelinux.0',
#  }
#
#  dhcp::pool{ 'localdomain':
#    network     => '192.168.5.0',
#    mask        => '255.255.255.0',
#    range       => '192.168.5.101 192.168.5.250',
#    nameservers => [ '192.168.5.100' ],
#    pxeserver   => '192.168.5.100',
#  }

}
