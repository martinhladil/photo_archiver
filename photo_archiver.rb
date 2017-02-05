#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
Bundler.require(:default)
require_relative "photo_archiver/cli"

begin
  PhotoArchiver::CLI.start(ARGV)
rescue PhotoArchiver::PhotoArchiverError => exception
  puts Paint[exception.message, :red]
end
