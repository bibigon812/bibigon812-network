# network

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with network](#setup)
    * [What network affects](#what-network-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with network](#beginning-with-network)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

This module manages network interfaces without restarting the network 
subsystem. It contains of two parts. One uses iproute2 tools and system files
placed in `/sys/class/net`. The other manages files needed to restore the state
after OS boots.

## Setup

### What network affects **OPTIONAL**

If it's obvious what your module touches, you can skip this section. For
example, folks can probably figure out that your mysql_instance module affects
their MySQL instances.

If there's more that they should know about, though, this is the place to mention:

* A list of files, packages, services, or operations that the module will alter,
  impact, or execute.
* Dependencies that your module automatically installs.
* Warnings or other important notices.

### Setup Requirements **OPTIONAL**

If your module requires anything extra before setting up (pluginsync enabled,
etc.), mention it here.

If your most recent release breaks compatibility or requires particular steps
for upgrading, you might want to include an additional "Upgrading" section
here.

### Beginning with network

The very basic steps needed for a user to get the module up and running. This
can include setup steps, if necessary, or it can be an example of the most
basic use of the module.

## Usage



```puppet
network_interface { ['eth0', 'eth1']:
    mtu => 9000,
}
```

### Create the bond interface
```puppet
network_interface { 'bond0':
    ensure         => present,
    bond_lacp_rate => 'fast',
    mtu            => 9000,
}
```

### Create the vlan interface
```puppet
network_interface { 'bond0.100':
    ensure => present,
    ipaddress => [
        '10.0.0.1/24',
        '172.16.0.1/24',
    ],
}
```

```puppet
network_interface { 'vlan100':
    ensure => present,
    ipaddress => [
        '10.0.0.1/24',
        '172.16.0.1/24',
    ],
    parent => 'bond0',
}
```

```puppet
network_interface { 'super_vlan':
    ensure => present,
    ipaddress => [
        '10.0.0.1/24',
        '172.16.0.1/24',
    ],
    parent => 'bond0',
    tag    => 100,
}
```

## Reference

### network_interface

- `name`. Interface name.
- `type`. Interface type. Can be `hw`, `bond` and `vlan`.
- `bond_lacp_rate`. Option specifying the rate in which we'll ask our link
partner to transmit LACPDU packets in 802.3ad mode. Defaults to `slow`.
- `bond_miimon`. Specifies the MII link monitoring frequency in milliseconds.
Defaults to `100`.
- `bond_mode`. Specifies one of the bonding policies. Defaults to `802.3ad`.
- `bond_slaves`. Specifies a list of the bonding slaves. Defaults to `[]`.
- `bond_xmit_hash_policy`. This policy uses upper layer protocol information,
when available, to generate the hash. Defaults to `layer3+4`.
- `ipaddress`. Specifies a list of IP addresses. Defaults to `[]`.
- `mac`. Specifies a MAC address.
- `mtu`. Specifies the maximum transmission unit. Defaults to `1500`.
- `parent`. Specifies a parent interface.
- `state`. State of this interface. Can be `up` and `down`. Defaults to `up`.
- `tag`. Vlan ID.

## Limitations

This is where you list OS compatibility, version compatibility, etc. If there
are Known Issues, you might want to include them under their own heading here.

## Development

Since your module is awesome, other users will want to play with it. Let them
know what the ground rules for contributing are.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should
consider using changelog). You can also add any additional sections you feel
are necessary or important to include here. Please use the `## ` header.
