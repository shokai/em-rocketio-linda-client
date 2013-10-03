require File.expand_path 'test_helper', File.dirname(__FILE__)

class TestEmRocketIOLindaClient < MiniTest::Test

  def test_write_read_take
    ts_name = "ts_#{rand Time.now.to_i}"
    _tuple1 = nil
    _tuple2 = nil
    _tuple3 = nil
    _tuple4 = nil

    EM::run do
      client = EM::RocketIO::Linda::Client.new App.url
      ts = client.tuplespace[ts_name]

      client.io.on :connect do
        ts.write ["rw",1,2,3]
        ts.write ["rw",1,2,"a"]
        ts.write ["rw",1,"a",2]
        ts.take ["rw",1,2] do |tuple, info|
          _tuple1 = tuple
        end
        ts.read ["rw",1,2] do |tuple, info|
          _tuple2 = tuple
        end
        ts.take ["rw",1,2] do |tuple, info|
          _tuple3 = tuple
        end
        client2 = EM::RocketIO::Linda::Client.new App.url
        ts2 = client2.tuplespace[ts_name]
        client2.io.on :connect do
          ts2.take ["rw",1] do |tuple, info|
            _tuple4 = tuple
          end
        end
      end

      EM::defer do
        50.times do
          sleep 0.1
          break if _tuple4
        end
        EM::add_timer 1 do
          EM::stop
        end
      end
    end
    assert_equal _tuple1, ["rw",1,2,"a"] # take
    assert_equal _tuple2, ["rw",1,2,3] # read
    assert_equal _tuple3, ["rw",1,2,3] # take
    assert_equal _tuple4, ["rw",1,"a",2]
  end

  def test_watch
    results = []
    _tuple1 = nil
    _tuple2 = nil
    EM::run do
      client = EM::RocketIO::Linda::Client.new App.url
      ts = client.tuplespace["ts_#{rand Time.now.to_i}"]
      client.io.on :connect do
        ts.take ["watch",1,2] do |tuple, info|
          _tuple1 = tuple
        end
        ts.read ["watch",1,2] do |tuple, info|
          _tuple2 = tuple
        end
        ts.watch ["watch",1,2] do |tuple, info|
          results.push tuple
        end
        ts.write ["watch",1,2,3]
        ts.write ["watch",1,"a",2]
        ts.write ["watch",1,2,3,4]
      end

      EM::defer do
        50.times do
          sleep 0.1
          break if  _tuple1 != nil and _tuple2 != nil
        end
        EM::add_timer 1 do
          EM::stop
        end
      end
    end
    assert_equal _tuple1, ["watch",1,2,3]
    assert_equal _tuple2, ["watch",1,2,3,4]
    assert_equal results.size, 2
    assert_equal results[0], ["watch",1,2,3]
    assert_equal results[1], ["watch",1,2,3,4]
  end

  def test_tuplespaces
    _tuple1 = nil
    _tuple2 = nil

    EM::run do
      client = EM::RocketIO::Linda::Client.new App.url
      ts1 = client.tuplespace["ts1_#{rand Time.now.to_i}"]
      ts2 = client.tuplespace["ts2_#{rand Time.now.to_i}"]

      client.io.on :connect do
        ts2.take ["a"] do |tuple, info|
          _tuple2 = tuple
        end
        ts1.take [1] do |tuple, info|
          _tuple1 = tuple
        end
        ts1.write [1,2,3]
        ts2.write ["a","b","c"]
      end
      EM::defer do
        50.times do
          sleep 0.1
          break if _tuple1
        end
        EM::add_timer 1 do
          EM::stop
        end
      end
    end
    assert_equal _tuple1, [1,2,3]
    assert_equal _tuple2, ["a","b","c"]
  end

  def test_tuple_expire
    _tuple1 = nil
    _tuple2 = nil
    EM::run do
      client = EM::RocketIO::Linda::Client.new App.url
      ts = client.tuplespace["ts_#{rand Time.now.to_i}"]

      client.io.on :connect do
        ts.write ["expire",1,2,999], :expire => false
        ts.write ["expire",1,2,3], :expire => 10
        ts.write ["expire",1,2,"a","b"], :expire => 2
        ts.read ["expire",1,2] do |tuple, info|
          _tuple1 = tuple
        end
        sleep 3
        push :check_expire, nil
        ts.read ["expire",1,2] do |tuple, info|
          _tuple2 = tuple
        end
      end
      EM::defer do
        50.times do
          sleep 0.1
          break if _tuple2
        end
        EM::add_timer 1 do
          EM::stop
        end
      end
    end
    assert_equal _tuple1, ["expire",1,2,"a","b"]
    assert_equal _tuple2, ["expire",1,2,3]
  end
end
