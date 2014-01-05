module Keywork
  unless defined?(Keywork::VERSION)
    VERSION = '0.0.2'
    LOG_LEVELS = [:debug, :info, :warn, :error, :fatal]
    SETTINGS_CATEGORIES = [:client]
    STOP_SIGNALS = %w[INT TERM]
  end
end
