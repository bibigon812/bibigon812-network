require 'puppet/util/bibigon812/network'

Puppet::Type.newtype(:network_interface) do
  @doc = %q{
    This type provides the capabilities to manage generic parameters
    of network interfaces.
  }

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'Interface name.'

    Puppet::Util::Network::Interfaces.each_value do |opts|
      newvalues(opts[:name_regexp])
    end
  end

  newparam(:type) do
    desc 'Type of this iterface.'

    defaultto do
      Puppet::Util::Network::get_interface_type(resource[:name])
    end

    Puppet::Util::Network::Interfaces.each_key do |interface_type|
      newvalues(interface_type)
    end
  end

  newproperty(:ipaddress, array_matching: :all) do
    desc 'Specifies a list of IP addresses.'

    defaultto([])
    validate do |value|
      begin
        IPAddr.new(value)
      rescue
        fail('Invalid value \'%{value}\'. It is not a IP address.' % { value: value })
      end
      fail('Invalid value \'%{value}\'. Prefix length is not specified.' % {value: value }) unless value.include?('/')
    end

    def insync?(is)
      is.each do |value|
        return false unless @should.include?(value)
      end

      @should.each do |value|
        return false unless is.include?(value)
      end

      true
    end
  end

  newproperty(:mtu) do
    desc 'Specifies the maximum transmission unit.'

    validate do |value|
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 1-9000.' % { value: value } unless value >= 68 and value <= 9000
    end
  end

  newproperty(:state) do
    desc 'State of this interface.'
    newvalues(:up, :down)
    defaultto :up
  end
end

require 'puppet/type/network_interface/ethernet'      # ethernet
require 'puppet/type/network_interface/bonding'       # bonding
require 'puppet/type/network_interface/vlan'          # vlan
require 'puppet/type/network_interface/autorequire'   # autorequire
