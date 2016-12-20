#!/bin/bash

cat > Gemfile <<EOF
source 'https://rubygems.org'

gem "cocoapods"
gem "fetch_local_lib", :git => "https://github.com/fathens/fetch_local_lib.git"
gem "cordova_plugin_swift", :git => "https://github.com/fathens/Cordova-Plugin-Swift.git", :branch => "feature/gemlib"
EOF

bundle install

bundle exec ruby <<EOF
require 'pathname'
require 'fetch_local_lib'
require 'cordova_plugin_swift'

PLATFORM_DIR = Pathname('$0').realpath.dirname
PLUGIN_DIR = PLATFORM_DIR.dirname.dirname

ENV['PLUGIN_DIR'] = PLUGIN_DIR.to_s

plugin_xml = REXML::Document.new(File.open(PLUGIN_DIR/'plugin.xml'))

podfile = Podfile.new(element: plugin_xml.get_elements('//platform[@name="ios"]/podfile').first)
podfile.pods.unshift Pod.new(name: 'Cordova')
podfile.swift_version ||= '3.0'
podfile.ios_version ||= '10.0'

bridge_file = PLATFORM_DIR/".Bridging-Header.h"
File.open(bridge_file, 'w') { |dst|
    dst.puts podfile.pods.map {|p| p.bridging_headers }.flatten
}

proj = XcodeProject.new
proj.sources_pattern = "src/*.swift"
proj.build_settings = {
    "SWIFT_OBJC_BRIDGING_HEADER" => bridge_file ? bridge_file.relative_path_from(PLATFORM_DIR) : nil,
    "SWIFT_VERSION" => podfile.swift_version,
    "ENABLE_BITCODE" => "NO"
}

FetchLocalLib::Repo.bitbucket(PLUGIN_DIR, "lineadapter_ios", tag: "version/3.2.1").git_clone
target_name = proj.write("CordovaPlugin_#{PLUGIN_DIR.basename}")
podfile.write(PLATFORM_DIR/'Podfile', target_name)

log_header "pod install"
system "pod install"
EOF
