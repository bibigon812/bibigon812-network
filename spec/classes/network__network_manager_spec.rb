require 'spec_helper'

describe 'network::network_manager' do
  let(:hiera_config) { 'spec/data/hiera.yaml' }
  let(:title) { 'network::network_manager' }

  it { should contain_class('network::network_manager') }
end