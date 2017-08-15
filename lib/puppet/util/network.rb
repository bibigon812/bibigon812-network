module Puppet::Util::Network

  # Supported network interfaces.
  Interfaces = {
    bonding: {
      name_regexp: /\Abond\d+\Z/,
    },
    gre: {
      name_regexp: /\Agre\d+\Z/,
    },
    loopback: {
      name_regexp: /\Alo\Z/,
    },
    vlan: {
      name_regexp: /\Avlan([2-9]|[1-9][0-9]|[1-9][0-9]{2}|[1-3][0-9]{3}|40[0-8][0-9]|409[0-5])\Z/,
    },
    ethernet: {
      name_regexp: /\A([[:alpha:]]*(?:[[:alpha:]]\d+)+)\Z/,
    },
    unknown: {
      name_regexp: /\A\w+\Z/,
    }
  }

  # Variables
  Bonding  = :bonding
  Ethernet = :ethernet
  Gre      = :gre
  Loopback = :loopback
  Vlan     = :vlan
  Unknown  = :unknown

  Vlan1 = 1

  Down  = :down
  Up    = :up

  States = [
    Down,
    Up,
  ]

  Bondable = [
    :ethernet,
  ]

  Vlanable = [
    :bonding,
    :ethernet,
  ]

  # Get network interface type.
  # @param name [String] the network interface name.
  # @return [Symbol] the network interface type.
  def self.get_interface_type(name)

    return Unknown if name.nil?

    Interfaces.each do |type, opts|
      if opts[:name_regexp] =~ name
        return type
      end
    end

    Unknown
  end
end
