#
# process_server.rb - a sample code of how to use Open3.popen3
#
# github:
#     https://github.com/yoggy/popen3-test.rb
#
# license:
#     Copyright (c) 2017 yoggy <yoggy0@gmail.com>
#     Released under the MIT license
#     http://opensource.org/licenses/mit-license.php;
#
require 'open3'
require 'logger'

class ProcessServer
  def initialize(logging_io, cmd, &on_receive_block)
    @logging_io = logging_io
    @cmd = cmd
    @on_recieve_block = on_receive_block

    @wait_thread = nil
    @popen_thread = nil
    @read_thread = nil

    _start()
  end

  def log(msg)
    return if @logging_io.nil?

    msg = "ProcessServer.log():" + msg

    if @logging_io.kind_of?(Logger)
      @logging_io.debug(msg)
    elsif @logging_io.kind_of?(IO)
      @logging_io.puts(msg)
    end
  end

  def is_running
    return false if @wait_thread.nil?
    return false if @wait_thread.status.nil? || @wait_thread.status == false
    true
  end

  def _start()
    stop_inner()
    log "start() cmd=" + @cmd

    @popen_thread = Thread.start do
      begin
        Open3.popen3(@cmd) do |stdin, stdout, stderr, wait_thread|
          @wait_thread = wait_thread
          @read_thread = Thread.start do 
            begin
              loop do
                IO.select([stdout, stderr]).flatten.compact.each do |io|
                  io.each do |line|
                    next if line.nil? || line.empty?
                    @on_recieve_block.call(line) unless @on_recieve_block.nil?
                  end
                end
                break if stdout.eof? && stderr.eof?
              end
            rescue Exception => e
              log "IO object closed...e=" + e.inspect
            end
          end
          @wait_thread.join
          loop do
            break if stdout.eof? && stderr.eof?
            sleep 1
          end
        end
      rescue Exception => e
        log "spawn failed...e=" + e.inspect
      end
    end
    sleep 0.3
  end

  def stop()
    log "stop()"
    stop_inner()
    sleep 0.3
  end

  def stop_inner()
    return if @wait_thread.nil?

    begin
      Process.kill("KILL", @wait_thread.pid)
    rescue
    end

    @wait_thread = nil
    @popen_thread = nil
    @read_thread = nil
  end
end
