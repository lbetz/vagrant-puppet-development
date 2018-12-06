OS=$1
RELEASE=$2

#PUPPET_VERSION="5.5.7-1"
#PUPPET_PACKAGE="puppet-agent-${PUPPET_VERSION}.el${RELEASE}.x86_64.rpm"

function raise_error() {
  echo -e "\e[31mfailed\e[0m"
  exit 1
}

echo "Importing GPG key..."
rpm --import https://yum.puppet.com/RPM-GPG-KEY-puppet 2>/dev/null || raise_error

echo "Adding repository for Puppet..."
rpm -aq |grep puppet5-release 1>/dev/null || yum install -y "http://yum.puppet.com/puppet5/puppet5-release-el-${RELEASE}.noarch.rpm" &>/dev/null || raise_error

echo "Installing Puppet agent..."
rpm -q puppet-agent &>/dev/null || yum install -y puppet-agent &>/dev/null || raise_error
#rpm -q puppet-agent &>/dev/null || rpm -i "/vagrant/downloads/${PUPPET_PACKAGE}" &>/dev/null || raise_error

# structered facts
echo "Creating facts.d directory..."
mkdir -p /etc/puppetlabs/facter/facts.d &>/dev/null || raise_error

exit 0
