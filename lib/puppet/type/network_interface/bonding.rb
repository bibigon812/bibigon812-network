$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..",".."))
require 'puppet/util/network'

Puppet::Type.type(:network_interface).newproperty(:bond_lacp_rate) do
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

Puppet::Type.type(:network_interface).newproperty(:bond_miimon) do
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

Puppet::Type.type(:network_interface).newproperty(:bond_mode) do
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

Puppet::Type.type(:network_interface).newproperty(:bond_slaves, array_matching: :all) do
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

Puppet::Type.type(:network_interface).newproperty(:bond_xmit_hash_policy) do
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
