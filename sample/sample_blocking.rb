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
    ts.write [1,2,3]
    ts.write [1,2,3,4]
    ts.write [1,2,3,4,"abc"]

    EM::defer do
      loop do
        tuple = ts.take [1,2]  ## read tuple([1,2]) and delete
        puts "blocking take #{tuple}"
        list = ts.list [1,2]
        puts "#{list.size} tuples exists."
      end
    end

    EM::add_periodic_timer 1 do
      ts.write [1,2, Time.now]
    end
  end

end
