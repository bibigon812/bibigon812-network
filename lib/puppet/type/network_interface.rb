$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..",".."))
require 'puppet/util/network'

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

    defaultto { Puppet::Util::Network::get_interface_type(resource[:name]) }

    munge do |value|
      Puppet::Util::Network::get_interface_type(resource[:name])
    end
  end

  ##
  ## Generic
  ##
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

  ##
  ## Ethernet
  ##
  newproperty(:mac) do
    desc 'Specifies a MAC address.'
    newvalues(/\A(\h\h(?::|-)?){5}\h\h\Z/)
  end

  ##
  ## Bonding
  ##
  newproperty(:bond_lacp_rate) do
    desc %q{
      Option specifying the rate in which we'll ask our link partner to transmit
      LACPDU packets in 802.3ad mode.
    }

    defaultto do
      if Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Bonding
        :slow
      else
        nil
      end
    end

    newvalues(:slow, :fast)
  end

  newproperty(:bond_miimon) do
    desc 'Specifies the MII link monitoring frequency in milliseconds.'

    defaultto do
      if Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Bonding
        100
      else
        nil
      end
    end

    newvalues(/\A\d+\Z/)
  end

  newproperty(:bond_mode) do
    desc 'Specifies one of the bonding policies.'

    defaultto do
      if Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Bonding
        '802.3ad'
      else
        nil
      end
    end

    newvalues('balance-rr', 'active-backup', 'balance-xor', 'broadcast', '802.3ad', 'balance-tlb', 'balance-alb')
  end

  newproperty(:bond_slaves, array_matching: :all) do
    desc 'Specifies a list of the bonding slaves.'

    defaultto do
      if Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Bonding
        []
      else
        nil
      end
    end

    validate do |value|
      unless Puppet::Util::Network::Bondable.include? Puppet::Util::Network::get_interface_type(value)
        fail 'Invalid value. The interface %{value} cannot be a bond slave.' % {value: value}
      end
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

  newproperty(:bond_xmit_hash_policy) do
    desc 'This policy uses upper layer protocol information, when available, to generate the hash.'

    defaultto do
      if Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Bonding
        'layer3+4'
      else
        nil
      end
    end

    newvalues('layer2', 'layer3+4')
  end

  ##
  ## Vlan
  ##
  newproperty(:parent) do
    desc 'Specifies a parent interface.'

    validate do |value|
      unless Puppet::Util::Network::Vlanable.include? Puppet::Util::Network::get_interface_type(value)
        fail 'Invalid value. The interface \'%{value}\' cannot have vlan.' % {value: value}
      end
      if Puppet::Util::Network::get_interface_type(resource[:name]) == Puppet::Util::Network::Vlan and value.nil?
        fail 'Invalid value. The parent interface is not specified.'
      end
    end
  end

  newparam(:vlanid) do
    desc 'Contains a vlanid.'

    defaultto(Puppet::Util::Network::Vlan1)

    munge do |value|
      if resource[:type] == Puppet::Util::Network::Vlan
        Integer(Puppet::Util::Network::Interfaces[:vlan][:name_regexp].match(resource[:name])[1])
      else
        nil
      end
    end
  end

  ##
  ## autorequire
  ##
  autorequire(:network_interface) do
    reqs = []

    if self[:type] == Puppet::Util::Network::Vlan
      reqs << self[:parent] unless self[:parent].nil?

    elsif self[:type] == Puppet::Util::Network::Bonding
      self[:bond_slaves].each do |slave|
        reqs << slave
      end
    end

    reqs
  end
end
