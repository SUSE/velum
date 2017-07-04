#!/usr/bin/env ruby

# This is a patched version of the `httpd` function defined inside of ruby's
# stdlib (see the `un.rb` file shipped with your ruby distribution).
# The upstream version cannot serve contents over https.
# A patch is going to be sent upstream, in the meantime this code does the job.

def httpd
  require "un"
  setup("", "BindAddress=ADDR", "Port=PORT", "MaxClients=NUM", "TempDir=DIR",
        "DoNotReverseLookup", "RequestTimeout=SECOND", "HTTPVersion=VERSION",
        "SSLCertificate=CERT", "SSLPrivateKey=KEY") do
    |argv, options|
    require 'webrick'

    opt = options[:RequestTimeout] and options[:RequestTimeout] = opt.to_i
    [:Port, :MaxClients].each do |name|
      opt = options[name] and (options[name] = Integer(opt)) rescue nil
    end
    unless argv.empty?
      options[:DocumentRoot] = argv.shift
    end

    if options[:SSLCertificate]
      require 'webrick/https'
      require 'openssl'
      options[:SSLCertificate] = OpenSSL::X509::Certificate.new(File.read(options[:SSLCertificate]))
      options[:SSLEnable] = true
    end

    if options[:SSLPrivateKey]
      options[:SSLPrivateKey] = OpenSSL::PKey::RSA.new(File.read(options[:SSLPrivateKey]))
    end
    s = WEBrick::HTTPServer.new(options)
    shut = proc {s.shutdown}
    Signal.trap("TERM", shut)
    Signal.trap("QUIT", shut) if Signal.list.has_key?("QUIT")
    if STDIN.tty?
      Signal.trap("HUP", shut) if Signal.list.has_key?("HUP")
      Signal.trap("INT", shut)
    end
    s.start
  end
end
