module Keywork
  unless defined?(Keywork::VERSION)
    VERSION = '0.0.1'
    LOG_LEVELS = [:debug, :info, :warn, :error, :fatal]
    STOP_SIGNALS = %w[INT TERM]
  end
end
