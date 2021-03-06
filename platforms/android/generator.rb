#!/bin/bash

cat > Gemfile <<EOF
source 'https://rubygems.org'

gem "fetch_local_lib", :git => "https://github.com/fathens/fetch_local_lib.git"
gem "cordova_plugin_kotlin", :git => "https://github.com/fathens/Cordova-Plugin-Kotlin.git"
EOF

bundle install && bundle update

cat > .generator.rb <<EOF
require 'pathname'
require 'cordova_plugin_kotlin'
require_relative 'hooks/before_plugin_install'

PLATFORM_DIR = Pathname('$0').realpath.dirname
PLUGIN_DIR = PLATFORM_DIR.dirname.dirname

fetch_lineadapter PLUGIN_DIR

write_build_gradle(PLATFORM_DIR/'build.gradle')

log "Generating project done"
log "Open by AndroidStudio. Thank you."
EOF

bundle exec ruby .generator.rb
