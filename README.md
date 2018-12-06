# Introduction

Vagrant boxes to test puppet manifests.

# Requirements

* Vagrant, recommended version >1.8
* Virtualbox
* r10k


# Setup

    $ sudo gem install r10k
    $ cd puppet
    $ r10k puppetfile install

# Run

    $ vagrant up <virtual machine> --provider virtualbox

