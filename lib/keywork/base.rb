# require gems
require 'rubygems'

gem 'oj', '2.0.9'
gem 'eventmachine', '1.0.3'

require 'time'
require 'uri'
require 'oj'

# require project files
require File.join(File.dirname(__FILE__), 'constants')
require File.join(File.dirname(__FILE__), 'utilities')
require File.join(File.dirname(__FILE__), 'cli')
require File.join(File.dirname(__FILE__), 'logstream')
# require File.join(File.dirname(__FILE__), 'settings')
# require File.join(File.dirname(__FILE__), 'extensions')
# require File.join(File.dirname(__FILE__), 'process')
# require File.join(File.dirname(__FILE__), 'io')
# require File.join(File.dirname(__FILE__), 'rabbitmq')

Oj.default_options = { :mode => :compat, :symbol_keys => true }

module Keywork
  class Base
    def initialize(options = {})
      @options = options
    end

    def logger
      logger = Logger.get
      if @options[:log_level]
        logger.level = @options[:log_level]
      end
      if @options[:log_file]
        logger.reopen(@options[:log_file])
      end
      logger.setup_traps
      logger
    end

    def settings
      settings = Settings.new
      settings.load_env
      settings.load_file(@options[:config_file]) if @options[:config_file]
      if @options[:config_dirs]
        @options[:config_dirs].each do |config_dir|
          settings.load_directory(config_dir)
        end
      end
      settings.validate
      settings.set_env
      settings
    end
    
    def setup_process
      process = Process.new
      process.daemonize if @options[:daemonize]
      process.write_pid(@options[:pid_file]) if @options[:pid_file]
    end
  end
end
