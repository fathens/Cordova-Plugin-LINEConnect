#!/usr/bin/env ruby

require 'pathname'
require_relative '../lib/git_repository'
require_relative '../lib/plugin_gradle'

puts "Working with #{$0}"

$PLUGIN_PLATFORM_DIR = Pathname(ENV['CORDOVA_HOOK'] || $0).realpath.dirname.dirname

repo_dir = GitRepository.lineadapter_android($PLUGIN_PLATFORM_DIR, '3.1.21').git_clone
PluginGradle.with_lineadapter($PLUGIN_PLATFORM_DIR, repo_dir).write
