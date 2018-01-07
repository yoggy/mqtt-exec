#!/usr/bin/ruby
require 'mqtt'
require 'yaml'
require 'ostruct'
require 'csv'
require 'pp'
require_relative 'process_server'

$stdout.sync = true
Dir.chdir(File.dirname($0))
$current_dir = Dir.pwd

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

$log.info "$current_dir=" + $current_dir

$conf = OpenStruct.new(YAML.load_file("config.yaml"))

conn_opts = {
  remote_host: $conf.mqtt_host
}

if !$conf.mqtt_port.nil? 
  conn_opts["remote_port"] = $conf.mqtt_port
end

if $conf.mqtt_use_auth == true
  conn_opts["username"] = $conf.mqtt_username
  conn_opts["password"] = $conf.mqtt_password
end

# subscribe topic -> cmd -> stdout topic
csv = CSV.read("topic2cmd.csv")
map = {}

csv.each do |l|
  next unless l.size == 2 || l.size == 3

  subscribe_topic = l[0]
  command         = l[1]
  stdout_topic    = l.size == 3 ? l[2] : nil

  next if subscribe_topic[0] == "#" # comment line

  map[subscribe_topic] ={:command => command, :stdout_topic => stdout_topic}
  
  $log.info "subscribe_topic=#{subscribe_topic}, command=#{command}, stdout_topic=#{stdout_topic}"
end

$log.info "connecting..." 
MQTT::Client.connect(conn_opts) do |c|
  $log.info "connected!" 

  map.each do |k, v|
    c.subscribe(k)
  end

  c.get do |topic, message|
    h = map[topic]
    return if h.nil?

    command = h[:command]
    stdout_topic = h[:stdout_topic]
    
    $log.info "receive: topic=#{topic}, command=#{command}, stdout_topic=#{stdout_topic}"

    msg = ""
    p = ProcessServer.new($log, command) do |m|
      msg += m
    end

    20.times do
      sleep 0.2
      break if p.is_running == false
    end
    p.stop

    unless stdout_topic.nil?
      $log.info "publish: topic=#{stdout_topic}, msg=#{msg}"
      c.publish(stdout_topic, msg)
    end
  end
end

