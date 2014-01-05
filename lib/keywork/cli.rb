require 'optparse'

module Keywork
  class CLI
    def self.read(args = ARGV)
      options = {}
      optparse = OptionParser.new do |opts|
        opts.on('-h', '--help', 'Display this message') do
          return_output(opts)
        end
        opts.on('-V', '--version', 'Display version') do
          return_output(VERSION)
        end
        opts.on('-l', '--log FILE', 'Log to a given FILE. Default: STDOUT') do |file|
          options[:log_file] = file
        end
        opts.on('-L', '--log_level LEVEL', 'Log severity LEVEL') do |level|
          log_level = level.to_s.downcase.to_sym
          unless LOG_LEVELS.include?(log_level)
            puts 'Unknown log level: ' + level.to_s
            exit 1
          end
          options[:log_level] = log_level
        end
        opts.on('-v', '--verbose', 'Enable verbose logging') do
          options[:log_level] = :debug
        end
      end
      optparse.parse!(args)
      options
    end
    def self.return_output(info)
      puts info
      exit
    end
  end
end
