#!/bin/bash

cat > Gemfile <<EOF
source 'https://rubygems.org'

gem "fetch_local_lib", :git => "https://github.com/fathens/fetch_local_lib.git"
gem "cordova_plugin_kotlin", :git => "https://github.com/fathens/Cordova-Plugin-Kotlin.git", :branch => "feature/gemlib"
EOF

bundle install && bundle update

bundle exec ruby <<EOF
require 'pathname'
require 'fileutils'
require 'fetch_local_lib'
require 'cordova_plugin_kotlin'
require_relative 'hooks/after_plugin_install'

PLATFORM_DIR = Pathname('$0').realpath.dirname
PLUGIN_DIR = PLATFORM_DIR.dirname.dirname

fetch_lineadapter PLUGIN_DIR

cordova_srcdir = FetchLocalLib::Repo.github(PLUGIN_DIR, 'apache/cordova-android').git_clone/'framework'/'src'

write_build_gradle(PLATFORM_DIR/'build.gradle', cordova_srcdir)

log "Generating project done"
log "Open by AndroidStudio. Thank you."
EOF
