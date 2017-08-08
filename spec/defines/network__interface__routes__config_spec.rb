require 'spec_helper'

describe 'network::interface::routes::config' do
  let(:facts) do
    {
        os: {
            architecture: 'x86_64',
            family: 'RedHat',
            hardware: 'x86_64',
            name: 'CentOS',
            release: {
                full: '7.1.1503',
                major: '7',
                minor: '1'
            },
            selinux: {
                enabled: false
            }
        }
    }
  end

  let(:environment) { :sandbox }

  context 'eth0' do
    let(:title) { :eth0 }
    let(:params) do
      {
          config_dir: '/etc/sysconfig/network-scripts',
          routes:     [
              {
                  ensure:  :present,
                  device:  'eth0',
                  metric:  100,
                  nexthop: '192.168.0.1',
                  prefix:  '10.0.0.0/8',
              },
              {
                  ensure:  :present,
                  device:  'eth0',
                  nexthop: '192.168.0.1',
                  prefix:  '172.16.0.0/12',
              },
          ],
      }
    end

    it 'should contain routes' do
      is_expected.to contain_file('/etc/sysconfig/network-scripts/route-eth0').
          with_content(<<-OES
#
# Managed by Puppet in the sandbox environment
#
10.0.0.0/8 via 192.168.0.1 dev eth0 metric 100
172.16.0.0/12 via 192.168.0.1 dev eth0
      OES
      )
    end
  end
end