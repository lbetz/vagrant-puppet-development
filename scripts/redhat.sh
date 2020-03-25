OS=$1
RELEASE=$2

function raise_error() {
  echo -e "\e[31mfailed\e[0m"
  exit 1
}

if [ "X$OS" != "Xfedora" ]; then
  PKG="el"
else
  PKG="fedora"
fi

echo "Importing GPG key..."
rpm --import https://yum.puppet.com/RPM-GPG-KEY-puppet 2>/dev/null || raise_error

echo "Adding repository for Puppet..."
rpm -aq |grep puppet6-release 1>/dev/null || yum install -y "http://yum.puppet.com/puppet6-release-${PKG}-${RELEASE}.noarch.rpm" &>/dev/null || raise_error

echo "Installing Puppet agent..."
rpm -q puppet-agent &>/dev/null || yum install -y puppet-agent &>/dev/null || raise_error
echo "Removing production environment..."
rm -rf /etc/puppetlabs/code/environments/production &>/dev/null || raise_error

# structered facts
echo "Creating facts.d directory..."
mkdir -p /etc/puppetlabs/facter/facts.d &>/dev/null || raise_error

exit 0
