require 'spec_helper'

describe 'network::interface' do
  let(:title) { 'eth0' }

  it { is_expected.to compile.with_all_deps }
end