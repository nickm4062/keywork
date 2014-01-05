require 'optparse'

module Keywork
  class CLI
    def return_output(info)
      puts info
      exit
    end
    def self.read(args = ARGV)
      options = {}
      optparse = OptionParser.new do |opts|
        opts.on('-h', '--help', 'Display this message') do
          return_output(opts)
        end
        opts.on('-V', '--version', 'Display version') do
          return_output(VERSION)
        end
        optparse.parse!(args)
        options
      end
    end
  end
end
