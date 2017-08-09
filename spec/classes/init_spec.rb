require 'spec_helper'

describe 'network' do
  let(:hiera_config) { 'spec/data/hiera.yaml' }
  let(:title) { 'network' }
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

  it { should contain_class('network') }
  it { is_expected.to compile }
  it { is_expected.to compile.with_all_deps }
end
