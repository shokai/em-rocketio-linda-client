require 'rubygems'
require 'bundler/setup'
$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require 'minitest/autorun'
require "em-rocketio-linda-client"
require File.expand_path 'app', File.dirname(__FILE__)
