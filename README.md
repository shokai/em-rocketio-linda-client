em-rocketio-linda-client
========================
[Sinatra::RocketIO::Linda](https://github.com/shokai/sinatra-rocketio-linda) Client for eventmachine

* https://github.com/shokai/em-rocketio-client-linda


Installation
------------

    % gem install em-rocketio-linda-client

Usage
-----

```ruby
require 'eventmachine'
require 'em-rocketio-linda-client'

EM::run do
  linda = EM::RocketIO::Linda::Client.new('http://localhost:5000')
  ts = linda.tuplespace["test_space"]

  linda.io.on :connect do
    puts "#{linda.io.type} connect!! (sessin_id:#{linda.io.session})"
  end

  linda.io.on :disconnect do
    puts "#{io.type} disconnect"
  end

  io.on :error do |err|
    STDERR.puts err
  end

  ## watch Tuples
  ts.watch [1,2] do |tuple, info|
    p tuple
  end

  ## write a Tuple
  EM::add_periodic_timer 1 do
    ts.write [1, 2, Time.now]
  end
end
```


Sample
------

    % ruby sample/sample.rb


Test
----

    % gem install bundler
    % bundle install

start server

    % export PORT=5000
    % export WS_PORT=9000
    % bundle exec rake test_server

run test

    % bundle exec rake test


Contributing
------------
1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
