module Keywork
  class Process
    def initialize
      @logger = Logger.get
    end

    def write_pid(file)
      begin
        File.open(file, 'w') do |pid_file|
          pid_file.puts(::Process.pid)
        end
      rescue
        @logger.fatal('could not write to pid file',
                      :pid_file => file
        )
        @logger.fatal('KEYWORK NOT RUNNING!')
        exit 2
      end
    end

    def daemonize
      srand
      exit if fork
      unless ::Process.setsid
        @logger.fatal('cannot detach from controlling terminal')
        @logger.fatal('KEYWORK NOT RUNNING!')
        exit 2
      end
      Signal.trap('SIGHUP', 'IGNORE')
      exit if fork
      Dir.chdir('/')
      ObjectSpace.each_object(IO) do |io|
        unless [STDIN, STDOUT, STDERR].include?(io)
          begin
            io.close unless io.closed?
          rescue
          end
        end
      end
    end
  end
end
