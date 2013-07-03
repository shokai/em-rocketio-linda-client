#!/usr/bin/env ruby
require "rubygems"
$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require 'em-rocketio-linda-client'

EM::run do
  client = EM::RocketIO::Linda::Client.new "http://linda.shokai.org"
  ts = client.tuplespace["test_spae"]

  client.io.on :connect do
    puts "connect #{client.io.type} (#{client.io.session})"
    ts.write [1,2,3]
    ts.write [1,2,3,4]
    ts.write [1,2,3,4,"abc"]

    EM::defer do
      loop do
        tuple = ts.take [1,2]
        puts "blocking take #{tuple}"
      end
    end

    EM::add_periodic_timer 1 do
      ts.write [1,2, Time.now]
    end
  end

end
