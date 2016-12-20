#!/usr/bin/env ruby

require 'pathname'
require 'fetch_local_lib'

puts "Working with #{$0}"

$PLUGIN_DIR = Pathname(ENV['CORDOVA_HOOK'] || $0).realpath.dirname.dirname.dirname.dirname

FetchLocalLib::Repo.bitbucket($PLUGIN_DIR, "lineadapter_android1", tag: "version/3.1.21").git_clone
