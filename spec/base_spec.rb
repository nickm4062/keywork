require File.dirname(__FILE__) + '/helpers.rb'
require File.dirname(__FILE__) + '/../lib/keywork/base.rb'

describe 'Keywork::Base' do
  include Helpers
  before do
    @base = Keywork::Base.new
  end
end
