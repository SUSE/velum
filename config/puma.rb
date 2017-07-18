MAX_THREADS = ENV.fetch("VELUM_THREADS", 5).freeze
MAX_WORKERS = ENV.fetch("VELUM_WORKERS", 2).freeze

# frozen_string_literal: true
# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum, this matches the default thread size of Active Record.
#
threads MAX_THREADS, MAX_THREADS

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# TODO: remove this again when switching to a reverse proxy container
workers MAX_WORKERS

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory. If you use this option
# you need to make sure to reconnect any threads in the `on_worker_boot`
# block.
#
# preload_app!

# The code in the `on_worker_boot` will be called if you are using
# clustered mode by specifying a number of `workers`. After each worker
# process is booted this block will be run, if you are using `preload_app!`
# option you will want to use this block to reconnect to any threads
# or connections that may have been created at application boot, Ruby
# cannot share connections between processes.
#
# on_worker_boot do
#   ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
# end

pidfile "/tmp/puma.pid"
state_path "/tmp/puma.state"

if ENV["VELUM_PORT"].to_i == 443
  ssl_bind "0.0.0.0", ENV["VELUM_PORT"], key: "/etc/pki/velum.key", cert: "/etc/pki/velum.crt"
else
  bind "tcp://0.0.0.0:#{ENV["VELUM_PORT"]}"
end
