require File.expand_path 'test_helper', File.dirname(__FILE__)

class TestBlockingReadTake < MiniTest::Test

  def test_blocking_take
    ts_name = "ts_#{rand Time.now.to_i}"
    results = Array.new

    EM::run do
      client = EM::RocketIO::Linda::Client.new App.url
      ts = client.tuplespace[ts_name]
      
      client.io.on :connect do
        1.upto(3) do |i|
          ts.write ["blocking", "take", i]
        end

        client2 = EM::RocketIO::Linda::Client.new App.url
        ts2 = client2.tuplespace[ts_name]
        client2.io.on :connect do
          EM::defer do
            loop do
              results.push ts2.take ["blocking", "take"]
            end
          end
        end
      end

      EM::defer do
        50.times do
          sleep 0.1
          break if results.size > 2
        end
        EM::add_timer 1 do
          EM::stop
        end
      end
    end

    assert_equal results.size, 3
    assert_equal results.shift, ["blocking", "take", 3]
    assert_equal results.shift, ["blocking", "take", 2]
    assert_equal results.shift, ["blocking", "take", 1]
  end

end
