require 'spec_helper'

describe 'network::interface::config_file' do
  let(:title) { '/etc/sysconfig/netwrok-scripts/ifcfg-eth0' }

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_file('/etc/sysconfig/netwrok-scripts/ifcfg-eth0') }
end