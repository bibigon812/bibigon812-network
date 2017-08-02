# network

[![Build Status](https://travis-ci.org/bibigon812/bibigon812-network.svg?branch=master)](https://travis-ci.org/bibigon812/bibigon812-network)

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with network](#setup)
    * [What network affects](#what-network-affects)
    * [Beginning with network](#beginning-with-network)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)

## Description

This module manages network interfaces without restarting the network 
subsystem. It contains of two parts. One uses iproute2 tools and system files
placed in `/sys/class/net`. The other manages files needed to restore the state
after OS boots.

## Setup

### What network affects

* Removes unspecified IP addresses of the network interface.
* Overwrites configuration files of the network interface.
* Can make your server unreachable.

### Beginning with network

Include this module and write hiera.

```puppet
include ::network
```

```yaml
---
network::network_manager::enable: false
network::network_manager::ensure: stopped
```

```yaml
---
network::interfaces:
    eth0:
        mtu: 9000
    eth1:
        mtu: 9000
    bond0:
        bond_slaves:
            - eth0
            - eth1
        mtu: 9000
    bond0.100:
        ipaddress:
            - 10.0.0.1/24
            - 172.16.0.1/24
        mtu: 1500
    bond0.110:
        ipaddress:
            - 192.168.255.1/24
        mtu: 9000
```

## Usage

```puppet
network_interface { ['eth0', 'eth1']:
    mtu => 9000,
}
```

```yaml
---
network::interfaces:
    eth0:
        mtu: 9000
    eth1:
        mtu: 9000
```

### Create the bond interface
```puppet
network_interface { 'bond0':
    ensure         => present,
    bond_lacp_rate => 'fast',
    bond_slaves    => [
        'eth0',
        'eth1',
    ],
    mtu            => 9000,
}
```

```yaml
---
network::interfaces:
    bond0:
        ensure: present
        bond_lacp_rate: fast
        bond_slaves:
            - eth0
            - eth1
        mtu: 9000
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

```yaml
---
network::interfaces:
    bond0.100:
        ipaddress:
            - 10.0.0.1/24
            - 172.16.0.1/24
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

```yaml
---
network::interfaces:
    vlan100:
        ipaddress:
            - 10.0.0.1/24
            - 172.16.0.1/24
        parent: bond0
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
