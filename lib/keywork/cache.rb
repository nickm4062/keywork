require File.join(File.dirname(__FILE__), 'base')

module Keywork
  class Cache
    include Utilities
    def self.run(options = {})
      cache = self.new(options)
      EM.run do
        cache.start
        cache.trap_signals
      end
    end

    def initialize(options = {})
      base = Base.new(options)
      @logger = base.logger
      @settings = base.settings
      # @extensions = base.extensions
      base.setup_process
      # @extensions.load_settings(@settings.to_hash)
      @timers = []
      @checks_in_progress = []
      # @safe_mode = @settings[:client][:safe_mode] || false
    end

    def start
      # setup_redis
      # setup_rabbitmq
      # Thin::Logging.silent = true
      # bind = $settings[:api][:bind] || '0.0.0.0'
      # Thin::Server.start(bind, $settings[:api][:port], self)
    end

    def stop
      # $logger.warn('stopping')
      # $rabbitmq.close
      # $redis.close
      # $logger.warn('stopping reactor')
      # EM::stop_event_loop
    end

    def trap_signals
      $signals = Array.new
      STOP_SIGNALS.each do |signal|
        Signal.trap(signal) do
          $signals << signal
        end
      end
      EM::PeriodicTimer.new(1) do
        signal = $signals.shift
        if STOP_SIGNALS.include?(signal)
          $logger.warn('received signal', {
            :signal => signal
          })
          stop
        end
      end
    end
  end
end
