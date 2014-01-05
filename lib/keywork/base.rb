# require gems
require 'rubygems'

# require project files
require File.join(File.dirname(__FILE__), 'constants')

module Keywork
  class Base
    def initialize(options = {})
      @options = options
    end
  end
end
