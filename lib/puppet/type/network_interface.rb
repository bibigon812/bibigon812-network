Puppet::Type.newtype(:network_interface) do
  @doc = 'This type provides the capabilities to manage network interface paramaters'

  ensurable do
    newvalue(:absent) do
      provider.destroy
    end

    newvalue(:disabled, event: :interface_disabled) do
      provider.disable
    end

    newvalue(:enabled, event: :interface_enabled) do
      provider.create
    end

    aliasvalue(:present, :enabled)

    defaultto { :enabled }

    def retrieve
      provider.state
    end
  end

  newparam(:name, namevar: true) do
    desc 'Interface name.'
    newvalues(/\Abond\d+(\.\d+)?\Z/)
    newvalues(/\Avlan\d+\Z/)
    newvalues(/\A[[:alpha:]]+\w+(\.\d+)?\Z/)
  end

  newparam(:type) do
    desc 'Type of this interface.'

    newvalues(:eth, :bond, :vlan)
    defaultto {
      if resource[:name].include?('.') or resource[:name].include?('vlan')
        :vlan
      elsif resource[:name].include?('bond')
        :bond
      else
        :eth
      end
    }
  end

  newproperty(:ipaddress, array_matching: :all) do
    desc 'IP addresses'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        fail 'Invalid value \'%{value}\'. It is not a IP address.' % { value: value }
      end
      fail 'Invalid value \'%{value}\'. Prefix length is not specified.' % {value: value } unless value.include?('/')
    end
  end

  newproperty(:mac) do
    desc 'MAC address.'

    newvalues(/\A(\h\h(?::|-)?){5}\h\h\Z/)
  end

  newproperty(:mtu) do
    desc 'Maximum transmission unit.'

    validate do |value|
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 1500-9000.' % { value: value } unless value >= 1500 and value <= 9000
    end
  end

  newproperty(:parent) do
    desc 'Parent interface.'
    defaultto {
      if resource[:name].include?('.')
        resource[:name].split('.').first
      else
        nil
      end
    }

    validate do |value|
      type = if resource[:name].include?('.') or resource[:name].include?('vlan')
               :vlan
             elsif resource[:name].include?('bond')
               :bond
             else
               :eth
             end

      fail 'Invalid value \'%{value}\'. This interface type does not support parent interface.' % { value: value } if type == :eth
      fail 'Invalid value \'%{value}\'.' % { value: value } unless value == resource[:name].split('.').first
    end
  end

  newproperty(:tag) do
    desc 'Vlan ID.'

    defaultto {
      begin
        if resource[:name].include?('.')
          Integer(resource[:name].split('.').last)
        elsif resource[:name].include?('vlan')
          Integer(resource[:name].sub(/\Avlan/, ''))
        else
          nil
        end
      rescue
        nil
      end
    }

    validate do |value|
      type = if resource[:name].include?('.') or resource[:name].include?('vlan')
               :vlan
             elsif resource[:name].include?('bond')
               :bond
             else
               :eth
             end

      fail 'Invalid value \'%{value}\'. This interface type does not support tagging.' % { value: value } unless type == :vlan
      fail 'Invalid value \'%{value}\'. Valid value is an Integer.' % { value: value } unless value.is_a?(Integer)
      fail 'Invalid value \'%{value}\'. Valid values are 1-4095.' % { value: value } unless value >= 1 and value <= 4095
    end
  end
end