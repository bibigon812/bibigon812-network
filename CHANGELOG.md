## [1.1.3] - 2017-08-17

### Fixed

- 0.0.0.0/0 is the `default`

### Updated

- the changelog

## [1.1.2] - 2017-08-16

### Fixed

- the instantiation of the network_interface resource

## [1.1.1] - 2017-08-16

### Fixed

- changing the parent of a network interface

### Updated

- the changelog

## [1.1.0] - 2017-08-16

### Changed

- all IP address are stored in a file, ex. `ifcfg-eth0`

### Removed

- the template for interface aliases

## [1.0.2] - 2017-08-09

### Fixed

- creating routes

## [1.0.1] - 2017-08-09

### Fixed

- the README.md
- dates in the CHANGELOG.md

## [1.0.0] - 2017-08-09

### Added

- the `network_route` resource type

### Changed

- the `network::interface_config_dir` parameter to `network::config_dir`

### Fixed

- removing the vlan interface

## [0.1.1] - 2017-08-03

### Updated

- the alias file management

## [0.1.0] - 2017-08-02

### Added

- the resource type `network_interface`
- the provider `iproute2` for the resource type `network_interface`
- the class `network::network_manager`
- the define `network::interface`
- the define `network::interface::config`
