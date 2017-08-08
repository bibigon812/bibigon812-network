require 'spec_helper'

describe Puppet::Type.type(:network_route).provider(:iproute2) do
  describe 'instances' do
    it 'should have an instance method' do
      expect(described_class).to respond_to :instances
    end
  end

  let(:output) do
    <<-EOS
default via 10.0.2.2 dev eth0
10.0.0.0/24 dev vlan100  proto kernel  scope link  src 10.0.0.1
10.0.2.0/24 dev eth0  proto kernel  scope link  src 10.0.2.15
169.254.0.0/16 dev eth0  scope link  metric 1002
169.254.0.0/16 dev eth1  scope link  metric 1003
169.254.0.0/16 dev bond0  scope link  metric 1004
169.254.0.0/16 dev vlan100  scope link  metric 1005
172.16.0.0/24 dev vlan100  proto kernel  scope link  src 172.16.0.1
172.16.2.0/24 via 172.16.0.2 dev vlan100
172.16.3.0/24 via 172.16.0.3 dev vlan100
172.16.3.0/24 via 172.16.0.3 dev vlan100  metric 1
172.16.3.0/24 via 172.16.0.3 dev vlan100  metric 100
172.16.4.0/24 via 172.16.0.4 dev vlan100
172.16.32.0/24 dev eth1  proto kernel  scope link  src 172.16.32.103
EOS
  end

  context 'ip route output' do
    it 'should not return resources' do
      expect(described_class.instances.size).to eq(0)
    end
  end

  let(:provider) do
    described_class.new(
        ensure: :present,
        provider: :iproute2,
    )
  end

  let(:catalog) { Puppet::Resource::Catalog.new }

  describe 'prefetch' do
    before :each do
      described_class.stubs(:ip).with(%w{route list 172.16.3.0/24}).
          returns <<-EOS
172.16.3.0/24 via 172.16.0.3 dev vlan100
172.16.3.0/24 via 172.16.0.3 dev vlan100  metric 1
172.16.3.0/24 via 172.16.0.3 dev vlan100  metric 100
      EOS
    end


    context 'network_route \'172.16.3.0/24\'' do
      let(:resources) do
        hash = {}
            [0, 1, 100].each do |metric|
              hash["172.16.3.0/24 #{metric}"] = Puppet::Type.type(:network_route).new(title: "172.16.3.0/24 #{metric}")
            end
        hash
      end

      it 'with metric 0, 1, 100' do
        described_class.prefetch(resources)
        expect(resources['172.16.3.0/24 0'].provider.prefix).to eq('172.16.3.0/24')
        expect(resources['172.16.3.0/24 0'].provider.nexthop).to eq('172.16.0.3')
        expect(resources['172.16.3.0/24 0'].provider.device).to eq('vlan100')
        expect(resources['172.16.3.0/24 0'].provider.metric).to eq(0)

        expect(resources['172.16.3.0/24 1'].provider.prefix).to eq('172.16.3.0/24')
        expect(resources['172.16.3.0/24 1'].provider.nexthop).to eq('172.16.0.3')
        expect(resources['172.16.3.0/24 1'].provider.device).to eq('vlan100')
        expect(resources['172.16.3.0/24 1'].provider.metric).to eq(1)

        expect(resources['172.16.3.0/24 100'].provider.prefix).to eq('172.16.3.0/24')
        expect(resources['172.16.3.0/24 100'].provider.nexthop).to eq('172.16.0.3')
        expect(resources['172.16.3.0/24 100'].provider.device).to eq('vlan100')
        expect(resources['172.16.3.0/24 100'].provider.metric).to eq(100)
      end
    end
  end

  describe '#create' do
    before :each do
      provider.stubs(:exists?).returns(false)
    end

    [0, 100].each do |metric|
      context 'network_route \'172.16.0.0/24\'' do
        let(:resource) do
          Puppet::Type.type(:network_route).new(
              title:   "172.16.0.0/24 #{metric}",
              nexthop: '192.168.0.1',
          )
        end
        it "with metric #{metric}" do
          resource.provider = provider
          provider.expects(:ip).with(['route', 'add', '172.16.0.0/24', 'via', '192.168.0.1', 'metric', metric.to_s])
          provider.create
        end
      end
    end
  end

  describe '#destroy' do
    before :each do
      provider.stubs(:exists?).returns(true)
    end

    [0, 100].each do |metric|
      context 'network_route \'172.16.0.0/24\'' do
        let(:provider) do
          described_class.new(
              ensure:   :present,
              device:   'vlan100',
              prefix:   '172.16.0.0/24',
              metric:   metric,
              nexthop:  '192.168.0.1',
              provider: :iproute2,
          )
        end
        it "with metric #{metric}" do
          provider.expects(:ip).with(['route', 'delete', '172.16.0.0/24', 'via', '192.168.0.1', 'dev', 'vlan100', 'metric', metric.to_s])
          provider.destroy
        end
      end
    end
  end

  describe '#flush' do
    before :each do
      provider.stubs(:exists?).returns(true)
    end

    [0, 100].each do |metric|
      context 'network_route \'172.16.0.0/24\'' do
        let(:provider) do
          described_class.new(
              ensure:   :present,
              device:   'vlan100',
              prefix:   '172.16.0.0/24',
              metric:   metric,
              nexthop:  '192.168.0.2',
              provider: :iproute2,
          )
        end
        it "with metric #{metric}" do
          provider.expects(:ip).with(['route', 'change', '172.16.0.0/24', 'via', '192.168.0.1', 'dev', 'vlan100', 'metric', metric.to_s])
          provider.nexthop = '192.168.0.1'
          provider.flush
        end
      end
    end
  end
end