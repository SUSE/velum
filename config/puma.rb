WORKERS = ENV.fetch("VELUM_WORKERS", 8).freeze
MIN_THREADS = ENV.fetch("VELUM_MIN_THREADS", 8).freeze
MAX_THREADS = ENV.fetch("VELUM_MAX_THREADS", 32).freeze
SOCKET_NAME = ENV.fetch("VELUM_SOCKET_NAME", "dashboard.sock").freeze

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum, this matches the default thread size of Active Record.
#
threads MIN_THREADS, MAX_THREADS

workers WORKERS

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

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

bind "unix:///var/run/puma/#{SOCKET_NAME}"
