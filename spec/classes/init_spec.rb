require 'spec_helper'
describe 'network' do
  context 'with default values for all parameters' do
    it { should contain_class('network') }
  end
end
