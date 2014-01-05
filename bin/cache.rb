#!/usr/bin/env ruby

# unless $LOAD_PATH.include?(File.dirname(__FILE__) + '/../lib/')
#   $LOAD_PATH << File.dirname(__FILE__) + '/../lib'
# end

unless $:.include?(File.dirname(__FILE__) + '/../lib/')
  $: << File.dirname(__FILE__) + '/../lib'
end

require 'keywork/cache'

options = Keywork::CLI.read
Keywork::Cache.run(options)
