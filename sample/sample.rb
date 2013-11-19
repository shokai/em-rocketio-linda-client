#!/usr/bin/env ruby
require "rubygems"
$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require 'em-rocketio-linda-client'

url = ARGV.empty? ? "http://linda.shokai.org" : ARGV.shift

EM::run do
  client = EM::RocketIO::Linda::Client.new url
  ts = client.tuplespace["test_spae"]

  client.io.on :connect do
    puts "connect #{client.io.type} (#{client.io.session})"

    ts.watch [1,2] do |tuple, info|
      p tuple
    end

    EM::add_periodic_timer 1 do
      ts.write [1,2, Time.now]

      ts.list [1,2] do |list|
        puts "#{list.size} tuples in exists"
      end
    end
  end

end
