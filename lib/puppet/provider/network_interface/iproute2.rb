Puppet::Type.type(:network_interface).provide(:iproute2) do
  @doc = 'Manages network interface parameters'

  commands ip: 'ip'

  @resource_map = {
      ipaddress: {
          default: [],
          regexp: /\A\s+inet\s(\S+)\s/,
          type: :array,
      },
  }

  def self.instances
    providers = []

    hash = {}

    ip('addr').split(/\n/).collect do |line|
      if /\A\d+:\s(\S+):\s<[A-Z,_]+>\smtu\s(\d+)\sqdisc\s(\S+)\sstate\s(\S+)/ =~ line
        name = $1
        mtu = Integer($2)
        state = case $4
                  when 'UNKNOWN', 'UP'
                    :enable
                  when 'DOWN'
                    :disable
                  else
                    :absent
                end

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

        @resource_map.each do |property, options|
          if options[:type] == :array or options[:type] == :hash
            hash[property] = options[:default].clone
          else
            hash[property] = options[:default]
          end
        end

      else
        @resource_map.each do |property, options|
          if options[:regexp] =~ line
            value = $1
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

    unless hash.empty?
      debug 'Instantiated the interface: %{name}.' % { name: hash[:name] }
      providers << new(hash)
    end

    providers
  end
end