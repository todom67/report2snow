require 'spec_helper'
describe 'report2snow' do
  context 'with default values for all parameters' do
    it { should contain_class('report2snow') }
  end
end
