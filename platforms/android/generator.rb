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

PLATFORM_DIR = Pathname('$0').realpath.dirname
PLUGIN_DIR = PLATFORM_DIR.dirname.dirname

ENV['PLUGIN_DIR'] = PLUGIN_DIR.to_s

cordova_srcdir = FetchLocalLib::Repo.github(PLUGIN_DIR, 'apache/cordova-android').git_clone/'framework'/'src'

write_build_gradle(PLATFORM_DIR/'build.gradle', cordova_srcdir)

repo_dir = FetchLocalLib::Repo.bitbucket(PLATFORM_DIR, "lineadapter_android", tag: "version/3.1.21").git_clone
gradle = PluginGradle.new
gradle.jar_files.concat Pathname.glob(repo_dir/'*.jar')
gradle.jni_dirs.push repo_dir/'libs'
gradle.write PLATFORM_DIR/'plugin.gradle'

log "Generating project done"
log "Open by AndroidStudio. Thank you."
EOF
