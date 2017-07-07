#!/usr/bin/env ruby

require "webrick/https"
require "webrick"
require "optparse"
require "openssl"

def parse_options
  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: serve-init-page.rb [options] page.html"

    opts.on("-p", "--port PORT", "port") do |value|
      options[:Port] = value.to_i
    end

    opts.on("--request-timeout TIMEOUT", "request timeout") do |value|
      options[:RequestTimeout] = value.to_i
    end

    opts.on("--bind-address ADDRESS", "bind address") do |value|
      options[:BindAddress] = value
    end

    opts.on("--ssl-certificate CERT", "ssl certificate") do |value|
      options[:SSLCertificate] = value
    end

    opts.on("--ssl-private-key KEY", "ssl private key") do |value|
      options[:SSLPrivateKey] = value
    end

  end.parse!

  if ARGV.empty?
    puts "Static asset missing"
    exit(1)
  end

  [options, ARGV[0]]
end

options, asset = parse_options
contents = File.read(asset)

if options[:SSLCertificate]
  options[:SSLCertificate] = OpenSSL::X509::Certificate.new(
    File.read(options[:SSLCertificate])
  )
  options[:SSLEnable] = true
end

if options[:SSLPrivateKey]
  options[:SSLPrivateKey] = OpenSSL::PKey::RSA.new(
    File.read(options[:SSLPrivateKey])
  )
end

server = WEBrick::HTTPServer.new(options)
shut   = proc { server.shutdown }

Signal.trap("TERM", shut)
Signal.trap("QUIT", shut) if Signal.list.key?("QUIT")
if STDIN.tty?
  Signal.trap("HUP", shut) if Signal.list.key?("HUP")
  Signal.trap("INT", shut)
end

server.mount_proc "/" do |_, res|
  res.body   = contents
  res.status = 503
end

server.start
