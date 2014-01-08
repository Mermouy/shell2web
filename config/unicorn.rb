# config/unicorn.rb
worker_processes Integer(ENV['SHELL2WEB_CONCURRENCY'] || 3)
timeout Integer(ENV['SHELL2WEB_TIMEOUT'] || 1200)
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    $stderr.puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  ActiveRecord::Base.connection.disconnect! if defined?ActiveRecord::Base
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    $stderr.puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  ActiveRecord::Base.establish_connection if defined? ActiveRecord::Base
end
