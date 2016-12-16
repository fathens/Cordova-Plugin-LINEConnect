#!/usr/bin/env ruby

require 'pathname'
require_relative '../lib/git_repository'

puts "Working with #{$0}"

$PLUGIN_DIR = Pathname(ENV['CORDOVA_HOOK'] || $0).realpath.dirname.dirname.dirname.dirname

GitRepository.clone_lineadapter($PLUGIN_DIR)
