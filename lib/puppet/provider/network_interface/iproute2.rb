Puppet::Type.type(:network_interface).provide(:iproute2) do
  @doc = 'Manages network interface parameters'

  confine exists: '/usr/sbin/ip'
  commands ip: 'ip'

  @resource_map = {
      ipaddress: {
          default: [],
          regexp: /\A\s+inet\s(\S+)\s/,
          type: :array,
      },
      mac: {
          regexp: /\A\s+link\/ether\s(\S+)\s/,
          type: :string,
      }
  }

  def self.instances
    providers = []

    hash = {}

    ip('addr').split(/\n/).collect do |line|
      # Find a new interface
      if /\A\d+:\s(\S+):\s<[A-Z,_]+>\smtu\s(\d+)\sqdisc\s(\S+)\sstate\s(\S+)/ =~ line
        name = $1
        mtu = Integer($2)
        state = case $4
                  when 'UNKNOWN', 'UP'
                    :enabled
                  when 'DOWN'
                    :disabled
                  else
                    :absent
                end

        # Add hash to providers
        unless hash.empty?
          debug 'Instantiated the interface: %{name}.' % { name: hash[:name] }
          providers << new(hash)
        end

        hash = {
            ensure: state,
            mtu: mtu,
            name: name.split(/@/).first,
            provider: self.name,
        }

        # Add default values
        @resource_map.each do |property, options|
          next unless options.has_key?(:default)
          if options[:type] == :array or options[:type] == :hash
            hash[property] = options[:default].clone
          else
            hash[property] = options[:default]
          end
        end

      # Parse interface properties
      else
        @resource_map.each do |property, options|
          if options[:regexp] =~ line
            value = $1
            if value.nil?
              hash[property] = :true if options[:type] == :boolean
            else
              case options[:type]
                when :array
                  hash[property] << value

                when :fixnum
                  hash[property] = value.to_i

                when :boolean
                  hash[property] = :true

                else
                  hash[property] = value
              end
            end
          end
        end
      end
    end

    unless hash.empty?
      debug 'Instantiated the interface: %{name}.' % { name: hash[:name] }
      providers << new(hash)
    end

    providers
  end
end