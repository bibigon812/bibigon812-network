$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..",".."))
require 'puppet/util/network'

Puppet::Type.type(:network_interface).newproperty(:parent) do
  desc 'Specifies a parent interface.'

  validate do |value|
    unless Puppet::Util::Network::Vlanable.include? Puppet::Util::Network::get_interface_type(value)
      fail 'Invalid value. The interface \'%{value}\' cannot have vlan.' % {value: value}
    end
    if value.nil?
      fail 'Invalid value. The parent interface is not specified.'
    end
  end
end

Puppet::Type.type(:network_interface).newparam(:vlanid) do
  desc 'Contains a vlanid.'

  defaultto Puppet::Util::Network::Vlan1

  munge do |value|
    if Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Vlan
      Integer(Puppet::Util::Network::Interfaces[:vlan][:name_regexp].match(resource[:name])[1])
    else
      nil
    end
  end
end
