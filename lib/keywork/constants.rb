module Keywork
  unless defined?(Keywork::VERSION)
    VERSION = '0.0.2'
    LOG_LEVELS = [:debug, :info, :warn, :error, :fatal]
    SETTINGS_CATEGORIES = [:checks, :filters, :mutators, :handlers]
    EXTENSION_CATEGORIES = [:profilers, :checks, :mutators, :handlers]
    SEVERITIES = %w[ok warning critical unknown]
    STOP_SIGNALS = %w[INT TERM]
  end
end
