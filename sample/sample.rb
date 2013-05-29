#!/usr/bin/env ruby
require "rubygems"
$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require 'em-rocketio-linda-client'

EM::run do
  client = EM::RocketIO::Linda::Client.new "http://linda.shokai.org"
  ts = client.tuplespace["test_spae"]

  client.io.on :connect do
    puts "connect #{client.io.type}"

    ts.watch [1,2] do |tuple|
      p tuple
    end

    EM::add_periodic_timer 1 do
      ts.write [1,2, Time.now]
    end
  end

end
