$LOAD_PATH.unshift(File.join(File.dirname(__FILE__),"..",".."))
require 'puppet/util/network'

Puppet::Type.newtype(:network_interface) do
  @doc = %q{
    This type provides the capabilities to manage generic parameters
    of network interfaces.
  }

  ensurable do
    defaultvalues
    defaultto(:present)
  end

  newparam(:name, namevar: true) do
    desc 'Interface name.'
    newvalues(/\Abond\d+?\Z/)
    newvalues(/\Avlan\d+\Z/)
    newvalues(/\A([[:alpha:]]*([[:alpha:]]\d+)+)\Z/)
    newvalues(/\Alo\Z/)
  end

  newparam(:type) do
    desc 'Type of this interface.'

    newvalues(:bonding, :ethernet, :loopback, :unknown, :vlan)
    defaultto do
      case resource[:name]
      when /\Alo\Z/
        :loopback
      when /\Abond\d+?\Z/
        :bonding
      when /\Avlan\d+\Z/
        :vlan
      when /\A[[:alpha:]]*([[:alpha:]]\d+)+\Z/
        :ethernet
      else
        :unknown
      end
    end
  end

  newproperty(:ipaddress, array_matching: :all) do
    desc 'Specifies a list of IP addresses.'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        fail 'Invalid value \'%{value}\'. It is not a IP address.' % { value: value }
      end
      fail 'Invalid value \'%{value}\'. Prefix length is not specified.' % {value: value } unless value.include?('/')
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

    defaultto([])
  end

  newproperty(:mac) do
    desc 'Specifies a MAC address.'

    newvalues(/\A(\h\h(?::|-)?){5}\h\h\Z/)
  end

  newproperty(:mtu) do
    desc 'Specifies the maximum transmission unit.'

    validate do |value|
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 1-9000.' % { value: value } unless value >= 68 and value <= 9000
    end
  end

  newproperty(:parent) do
    desc 'Specifies a parent interface.'
    defaultto do
      if resource[:name].include?('.')
        resource[:name].split('.').first
      else
        nil
      end
    end

    validate do |value|
      type =
      case resource[:name]
      when /\Alo\Z/
        :loopback
      when /\Abond\d+?\Z/
        :bonding
      when /\Avlan\d+\Z/
        :vlan
      when /\A[[:alpha:]]*([[:alpha:]]\d+)+\Z/
        :ethernet
      else
        :unknown
      end

      fail 'Invalid value \'%{value}\'. This interface type does not support parent interface.' % { value: value } if type == :ethernet
    end
  end

  newproperty(:state) do
    desc 'State of this interface.'
    newvalues(:up, :down)
    defaultto :up
  end

  ##
  ## Bonding
  ##
  newproperty(:bond_lacp_rate) do
    desc %q{
      Option specifying the rate in which we'll ask our link partner to transmit
      LACPDU packets in 802.3ad mode.
    }

    newvalues(:slow, :fast)
    defaultto do
      if /\Abond\d+\Z/ =~ resource[:name]
        :slow
      else
        nil
      end
    end
  end

  newproperty(:bond_miimon) do
    desc 'Specifies the MII link monitoring frequency in milliseconds.'

    defaultto do
      if /\Abond\d+\Z/ =~ resource[:name]
        100
      else
        nil
      end

    validate do |value|
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 0-1000.' % { value: value } unless value >= 0 and value <= 1000
    end

    newvalues(/\A\d+\Z/)
  end

  newproperty(:bond_mode) do
    desc 'Specifies one of the bonding policies.'

    newvalues('balance-rr', 'active-backup', 'balance-xor', 'broadcast', '802.3ad', 'balance-tlb', 'balance-alb')
    defaultto do
      if /\Abond\d+\Z/ =~ resource[:name]
        '802.3ad'
      else
        nil
      end
    end
  end

  newproperty(:bond_slaves, array_matching: :all) do
    desc 'Specifies a list of the bonding slaves.'

    def insync?(is)
      is.each do |value|
        return false unless @should.include?(value)
      end

      @should.each do |value|
        return false unless is.include?(value)
      end

      true
    end

    defaultto do
      if /\Abond\d+\Z/ =~ resource[:name]
        []
      else
        nil
      end
    end
  end

  newproperty(:bond_xmit_hash_policy) do
    desc 'This policy uses upper layer protocol information, when available, to generate the hash.'

    newvalues('layer2', 'layer3+4')
    defaultto do
      if /\Abond\d+\Z/ =~ resource[:name]
        'layer3+4'
      else
        nil
      end
    end
  end

  ##
  ## Vlan
  ##
  newproperty(:vlanid) do
    desc 'Vlan ID.'

    defaultto do
      if /\Avlan(\d+)\Z/ =~ resource[:name]
        Integer($1)
      else
        nil
      end
    end

    validate do |value|
      type =
      case resource[:name]
      when /\Alo\Z/
        :loopback
      when /\Abond\d+?\Z/
        :bonding
      when /\Avlan\d+\Z/
        :vlan
      when /\A[[:alpha:]]*([[:alpha:]]\d+)+\Z/
        :ethernet
      else
        :unknown
      end

      fail 'Invalid value \'%{value}\'. This interface type does not support tagging.' % { value: value } unless type == :vlan
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 1-4095.' % { value: value } unless value >= 1 and value <= 4095
    end
  end

  ##
  ## autorequire
  ##
  autorequire(:network_interface) do
    reqs = []

    reqs += self[:bond_slaves] if self[:type] == :bonding
    reqs << self[:parent] if self[:parent]

    reqs
  end
end
