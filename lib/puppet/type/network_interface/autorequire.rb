$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..",".."))
require 'puppet/util/network'

Puppet::Type.type(:network_interface).autorequire(:network_interface) do
  reqs = []

  if Puppet::Util::Network::get_interface_type(self[:name]) == Puppet::Util::Network::Vlan
    reqs << self[:parent]
  elsif Puppet::Util::Network::get_interface_type(self[:name]) == Puppet::Util::Network::Bonding
    reqs += self[:bond_slaves]
  end

  reqs
end
