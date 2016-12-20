#!/usr/bin/env ruby

require 'pathname'
require 'fetch_local_lib'

puts "Working with #{$0}"

$PLUGIN_DIR = Pathname(ENV['CORDOVA_HOOK'] || $0).realpath.dirname.dirname.dirname.dirname

FetchLocalLib::Repo.bitbucket($PLUGIN_DIR, "lineadapter_ios", tag: "version/3.2.1").git_clone
