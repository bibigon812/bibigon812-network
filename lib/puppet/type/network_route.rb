Puppet::Type.newtype(:network_route) do
  @doc = 'This type provides the capabilities to manage network routes'

  ensurable do
    defaultvalues
    defaultto :present
  end

  def self.title_patterns
    [
        [ /\A(\S+)\Z/, [ [:prefix] ] ],
        [ /\A(\S+)\s+(\S+)\Z/, [ [:prefix], [:metric] ] ],
    ]
  end

  newparam(:prefix, namevar: true) do
    desc 'IP: address/prefix.'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        fail 'Invalid value \'%{value}\'. It is not a IP address.' % { value: value }
      end
      fail 'Invalid value \'%{value}\'. Prefix length is not specified.' % {value: value } unless value.include?('/')
    end
  end

  newparam(:metric, namevar: true) do
    desc 'Specifies metric.'

    newvalues(/\A\d+\Z/)

    validate do |value|
      super(value)
      v = Integer(value)
      fail 'Invalid value \'%{value}\'. Valid values are 0-255.' % { value: v } unless v >= 0 and v <= 255
    end

    munge do |value|
      Integer(value)
    end

    defaultto 0
  end

  newproperty(:device) do
    desc 'Specifies device which routes connected to.'
  end

  newproperty(:nexthop) do
    desc 'Specifies next hop destination'

    validate do |value|
      begin
        IPAddr.new value
      rescue
        fail 'Invalid value \'%{value}\'. It is not a IP address.' % { value: value }
      end
    end
  end

  autorequire(:network_interface) do
    [self[:device]] if self[:device]
  end
end
