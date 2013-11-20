require File.expand_path 'test_helper', File.dirname(__FILE__)

class TestBlockingReadTake < MiniTest::Test

  def test_blocking_take
    ts_name = "ts_blocking_take_#{rand Time.now.to_i}"
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


  def test_blocking_read
    ts_name = "ts_blocking_read_#{rand Time.now.to_i}"
    results = Array.new

    EM::run do
      client = EM::RocketIO::Linda::Client.new App.url
      ts = client.tuplespace[ts_name]
      client.io.on :connect do
        EM::defer do
          1.upto(3) do |i|
            ts.write ["blocking", "read", i]
            results.push ts.read ["blocking", "read"]
          end
          EM::add_timer 1 do
            EM::stop
          end
        end
      end
    end

    assert_equal results.size, 3
    assert_equal results.shift, ["blocking", "read", 1]
    assert_equal results.shift, ["blocking", "read", 2]
    assert_equal results.shift, ["blocking", "read", 3]
  end

  def test_blocking_list
    ts_name = "ts_blocking_list_#{rand Time.now.to_i}"
    _tuple1 = ["blocking", "a", "b", "c"]
    _tuple2 = ["blocking", "a", "b"]
    _tuple3 = ["blocking", "a", "b", "c", 1234]
    _result1 = nil
    _result2 = nil
    EM::run do
      client = EM::RocketIO::Linda::Client.new App.url
      ts = client.tuplespace[ts_name]
      client.io.on :connect do
        EM::defer do
          ts.write _tuple1
          ts.write _tuple2
          ts.write _tuple3
          _result1 = ts.list ["blocking", "a", "b"]
          _result2 = ts.list ["blocking", "a", "b", "c"]
        end
      end

      EM::defer do
        50.times do
          sleep 0.1
          break if _result2
        end
        EM::add_timer 1 do
          EM::stop
        end
      end
    end

    assert_equal _result1, [_tuple3, _tuple2, _tuple1]
    assert_equal _result2, [_tuple3, _tuple1]
  end

end
