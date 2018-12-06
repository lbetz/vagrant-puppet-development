OS=$1
RELEASE=$2

PUPPET_VERSION="5.5.7-1"
PUPPET_PACKAGE="puppet-agent_${PUPPET_VERSION}${RELEASE}_amd64.deb"

function raise_error() {
  echo -e "\e[31mfailed\e[0m"
  exit 1
}

echo "Importing GPG key..."
wget -q -O - http://apt.puppet.com/DEB-GPG-KEY-puppet 2>/dev/null | apt-key add - &>/dev/null || raise_error

echo "Adding repository for Puppet..."
if ! $(dpkg-query --show puppet5-release &>/dev/null); then
  wget -q "https://apt.puppet.com/puppet5-release-${RELEASE}.deb" 2>/dev/null || raise_error
  dpkg -i "puppet5-release-${RELEASE}.deb" &>/dev/null || raise_error
  rm -f "puppet5-release-${RELEASE}.deb" 2>/dev/null
fi

echo "Updating repository catalog..."
apt-get update &>/dev/null || raise_error

echo "Installing Puppet agent..."
dpkg-query --show puppet-agent &>/dev/null || apt-get -y install puppet-agent &>/dev/null
#dpkg-query --show puppet-agent &>/dev/null || dpkg -i "/vagrant/downloads/${PUPPET_PACKAGE}" &>/dev/null || raise_error

# structered facts
echo "Creating facts.d directory..."
mkdir -p /etc/puppetlabs/facter/facts.d 2>/dev/null || raise_error
