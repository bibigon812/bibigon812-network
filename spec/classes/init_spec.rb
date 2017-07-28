require 'spec_helper'

describe 'network' do
  let(:hiera_config) { 'spec/data/hiera.yaml' }
  let(:title) { 'network' }

  context 'with default values for all parameters' do
    it { should contain_class('network') }
  end
end
