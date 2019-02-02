OS=$1
RELEASE=$2

function raise_error() {
  echo -e "\e[31mfailed\e[0m"
  exit 1
}

echo "Importing GPG key..."
rpm --import https://yum.puppet.com/RPM-GPG-KEY-puppet 2>/dev/null || raise_error

echo "Adding repository for Puppet..."
rpm -aq |grep puppet5-release 1>/dev/null || zypper install -y "http://yum.puppet.com/puppet5/puppet5-release-sles-${RELEASE}.noarch.rpm" &>/dev/null || raise_error

echo "Installing Puppet agent..."
rpm -q puppet-agent &>/dev/null || zypper install -y puppet-agent &>/dev/null || raise_error

# structered facts
echo "Creating facts.d directory..."
mkdir -p /etc/puppetlabs/facter/facts.d &>/dev/null || raise_error

exit 0
