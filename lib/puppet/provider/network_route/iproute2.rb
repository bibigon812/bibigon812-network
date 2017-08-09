Puppet::Type.type(:network_route).provide(:iproute2) do
  @doc = 'Manages network interface parameters'

  confine exists: '/usr/sbin/ip'
  commands ip: 'ip'

  mk_resource_methods

  def self.instances
    []
  end

  def self.instance(prefix, metric)
    debug '[instance]'
    hash = get_provider_hash(prefix, metric)

    if hash.empty?
      debug 'Not found a network_route for prefix %{prefix} with metric %{metric}' % {prefix: prefix, metric: metric}
      nil
    else
      debug 'Found the network_route %{route}' % {route: hash.inspect}
      new(hash)
    end
  end

  def self.get_provider_hash(prefix, metric)
    debug '[get_provider_hash][%{prefix} %{metric}]' % {prefix: prefix, metric: metric}
    hash = {}

    if metric == 0
      pattern = /\A(\S+)(?:\s+via\s+(\S+))?(?:\s+dev\s+(\S+))?\Z/
    else
      pattern = /\A(\S+)(?:\s+via\s+(\S+))?(?:\s+dev\s+(\S+))?\s+metric\s+#{Regexp.escape(metric.to_s)}\Z/
    end

    ip(['route', 'list', prefix]).split(/\n/).collect do |line|
      if pattern =~ line.strip
        hash = {
            ensure:   :present,
            metric:   metric,
            name:     "#{prefix} #{metric}",
            prefix:   $1,
            provider: self.name,
        }
        hash[:device] = $3 unless $3.nil?
        hash[:nexthop] = $2 unless $2.nil?

        break
      end
    end

    hash
  end

  def self.prefetch(resources)
    debug '[prefetch]'
    resources.keys.each do |name|
      if provider = instance(resources[name][:prefix], resources[name][:metric])
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_hash = @resource.to_hash

    debug 'Creating the route \'%{route}\'' % {route: to_S}

    begin
      ip(get_ip_args(:add))
    rescue Exception => e
      notice e.message
    end
  end

  def destroy
    debug 'Creating the route \'%{route}\'' % {route: to_S}

    begin
      ip(get_ip_args(:delete))
    rescue Exception => e
      notice e.message
    end

    @property_hash.clear
  end

  def flush
    debug 'Flushing the route \'%{route}\'' % {route: to_S}

    begin
      ip(get_ip_args(:change))
    rescue Exception => e
      notice e.message
    end
  end

  def to_S
    out = "#{prefix} via #{nexthop}"
    out << " dev #{device}" unless device == :absent
    out << " metric #{metric}" unless metric == :absent
    out
  end

  def get_ip_args(command)
    cmd =  ['route', command.to_s, prefix]
    cmd += ['via', nexthop] unless nexthop == :absent
    cmd += ['dev', device] unless device == :absent
    cmd += ['metric', metric.to_s]
    cmd
  end
end