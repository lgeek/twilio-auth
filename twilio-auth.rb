#!/usr/bin/env ruby
require 'rubygems' # not necessary with ruby 1.9 but included for completeness
require 'twilio-ruby'
require 'socket'
require 'json'

@config_file = "#{ENV['HOME']}/.twilio-auth/config.json"
@blocklist_file = "#{ENV['HOME']}/.twilio-auth/blocklist.json"

def update_blocklist(blocklist)
  File.open(@blocklist_file, 'w') { |b| b.write blocklist.to_json }
end

def create_or_load_blocklist
  unless File.exists?(@blocklist_file)
    begin
      update_blocklist Hash.new
      return {}
    rescue
      abort "Can't create empty blocklist #{@blocklist_file}"
    end
  end

  return JSON.parse(File.new(@blocklist_file).read)
end

def send_text(code)
  twilio = Twilio::REST::Client.new @config['account_sid'], @config['auth_token']

  result = twilio.account.sms.messages.create(
    :from => @config['twilio_number'],
    :to => @config['own_number'],
    :body => ('Here\'s your OTP for ' + Socket.gethostname + ': ')[0...140] + code
  )

  return result
end

def generate_code(code_length)
  return (36**(code_length-1) + rand(36**code_length)).to_s(36)
end

def check_blocklist(client_ip)
  # Uncomment to use temporary blocking
  if @blocklist[client_ip] and @blocklist[client_ip]['count'] >= 3 #and (Time.now - Time.at(@blocklist[client_ip]['time'])) < 24*60*60
    abort "You're blocked!"
  end
end

def reset_count(client_ip)
  if @blocklist[client_ip] and @blocklist[client_ip]['count'] > 0
    @blocklist[client_ip]['count'] = 0
    update_blocklist(@blocklist)
  end
end

def increment_count(client_ip)
  if @blocklist[client_ip]
    @blocklist[client_ip]['count'] += 1
  else
    @blocklist[client_ip] = {}
    @blocklist[client_ip]['count'] = 1
  end
  @blocklist[client_ip]['time'] = Time.now.to_i
  update_blocklist(@blocklist)
end

@config = JSON.parse(File.new(@config_file).read)
@blocklist = create_or_load_blocklist

client_ip = ENV['SSH_CLIENT'].split(' ').first 

check_blocklist(client_ip)

code = generate_code(8)
send_text(code)

for tries in 0...3
  print "Enter the OTP: "
  if gets()[0...-1] == code
    reset_count(client_ip)
    Kernel.exec('$SHELL')
  else
    increment_count(client_ip)
    puts "Wrong OTP."
  end
  check_blocklist(client_ip)
end

abort
