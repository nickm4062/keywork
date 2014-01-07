module Keywork
  class Settings
    include Utilities
    attr_reader :indifferent_access, :loaded_env, :loaded_files
    def initialize
      @logger = Logger.get
      @settings = {}
      SETTINGS_CATEGORIES.each do |category|
        @settings[category] = {}
      end
      @indifferent_access = false
      @loaded_env = false
      @loaded_files = []
    end

    SETTINGS_CATEGORIES.each do |category|
      define_method(category) do
        @settings[category].map do |name, details|
          details.merge(:name => name.to_s)
        end
      end

      type = category.to_s.chop

      define_method((type + '_exists?').to_sym) do |name|
        @settings[category].key?(name.to_sym)
      end

      define_method(('invalid_' + type).to_sym) do |details, reason|
        invalid(reason,
                type => details
        )
      end
    end

    def load_env
      # Loads variables from environent if needed
      # if ENV['RABBITMQ_URL']
      #   @settings[:rabbitmq] = ENV['RABBITMQ_URL']
      #   @logger.warn('using rabbitmq url environment variable',
      #                :rabbitmq_url => ENV['RABBITMQ_URL']
      #   )
      # end
      @indifferent_access = false
      @loaded_env = true
    end

    def load_file(file)
      @logger.debug('loading config file', :config_file => file)
      if File.file?(file) && File.readable?(file)
        begin
          load_file_run(file)
        rescue Oj::ParseError => error
          load_file_rescue(error)
        end
      else
        @logger.error('config file does not exist or is not readable',
                      :config_file => file)
        @logger.warn('ignoring config file', :config_file => file)
      end
    end

    def load_file_run(file)
      contents = File.open(file, 'r').read
      config = Oj.load(contents, :mode => :strict)
      merged = deep_merge(@settings, config)
      unless @loaded_files.empty?
        changes = deep_diff(@settings, merged)
        @logger.warn('config file applied changes',
                     :config_file => file,
                     :changes => redact_sensitive(changes))
      end
      @settings = merged
      @indifferent_access = false
      @loaded_files << file
    end

    def load_file_rescue(error)
      @logger.error('config file must be valid json',
                    :config_file => file,
                    :error => error.to_s)
      @logger.warn('ignoring config file', :config_file => file)
    end

    def load_directory(directory)
      path = directory.gsub(/\\(?=\S)/, '/')
      Dir.glob(File.join(path, '**/*.json')).each do |file|
        load_file(file)
      end
    end

    def validate
      @logger.debug('validating settings')
      SETTINGS_CATEGORIES.each do |category|
        invalid(category.to_s + ' must be a hash') unless @settings[category].is_a?(Hash)
        send(category).each do |details|
          send(('validate_' + category.to_s.chop).to_sym, details)
        end
      end
      case File.basename($PROGRAM_NAME)
      when 'keywork'
        validate_keywork
      when 'kewwork-relay'
        validate_relay
      when 'rspec'
        # validate_keywork # cache
        # validate_relay
      end
      @logger.debug('settings are valid')
    end

    private

    def invalid(reason, data = {})
      @logger.fatal('invalid settings', {
        :reason => reason
      }.merge(data))
      @logger.fatal('KEYWORK NOT RUNNING!')
      exit 2
    end
  end

  class Validation < Keywork::Settings
    include Utilities
    attr_reader :indifferent_access, :loaded_env, :loaded_files
    def validate_subdue(type, details)
      condition = details[:subdue]
      data = {
        type => details
      }
      invalid(type + ' subdue must be a hash', data) unless condition.is_a?(Hash)
      if condition.key?(:at)
        unless %w[handler publisher].include?(condition[:at])
          invalid(type + ' subdue at must be either handler or publisher', data)
        end
      end
      if condition.key?(:begin) || condition.key?(:end)
        begin
          Time.parse(condition[:begin])
          Time.parse(condition[:end])
        rescue
          invalid(type + ' subdue begin & end times must be valid', data)
        end
      end
      if condition.key?(:days)
        invalid(type + ' subdue days must be an array', data) unless condition[:days].is_a?(Array)
        condition[:days].each do |day|
          days = %w[sunday monday tuesday wednesday thursday friday saturday]
          unless day.is_a?(String) && days.include?(day.downcase)
            invalid(type + ' subdue days must be valid days of the week', data)
          end
        end
      end
      if condition.key?(:exceptions)
        unless condition[:exceptions].is_a?(Array)
          invalid(type + ' subdue exceptions must be an array', data)
        end
        condition[:exceptions].each do |exception|
          unless exception.is_a?(Hash)
            invalid(type + ' subdue exceptions must each be a hash', data)
          end
          if exception.key?(:begin) || exception.key?(:end)
            begin
              Time.parse(exception[:begin])
              Time.parse(exception[:end])
            rescue
              invalid(type +
                      ' subdue exception begin & end times must be valid', data)
            end
          end
        end
      end
    end

    def validate_keywork
    end

    # def validate_api
    #   unless @settings[:api].is_a?(Hash)
    #     invalid('missing api configuration')
    #   end
    #   unless @settings[:api][:port].is_a?(Integer)
    #     invalid('api port must be an integer')
    #   end
    #  if @settings[:api].has_key?(:user) || @settings[:api].has_key?(:password)
    #     unless @settings[:api][:user].is_a?(String)
    #       invalid('api user must be a string')
    #     end
    #     unless @settings[:api][:password].is_a?(String)
    #       invalid('api password must be a string')
    #     end
    #   end
    # end
  end

  class Functions < Settings
    include Utilities
    attr_reader :indifferent_access, :loaded_env, :loaded_files
    def indifferent_access!
      @settings = with_indifferent_access(@settings)
      @indifferent_access = true
    end

    def to_hash
      indifferent_access! unless @indifferent_access
      @settings
    end

    def [](key)
      to_hash[key]
    end

    def set_env
      ENV['SENSU_CONFIG_FILES'] = @loaded_files.join(':')
    end
  end
end
