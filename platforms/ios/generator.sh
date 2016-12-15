#!/bin/bash

cd "$(dirname $0)"

title="CordovaPlugin_$(basename "$(cd ../../; pwd)")"
SWIFT_VERSION="$(cat .swift-version)"

echo "################################"
echo "#### Generate Xcodeproject"

echo "Project Name: $title"

cat <<EOF | ruby
require 'xcodeproj'

def build_settings(project, params)
    project.targets.each do |target|
        target.build_configurations.each do |conf|
            params.each do |key, value|
                conf.build_settings[key] = value
            end
        end
    end
end

project_name = "$title"
project = Xcodeproj::Project.new "#{project_name}.xcodeproj"

target = project.new_target(:framework, '$title', :ios)
project.recreate_user_schemes

group = project.new_group "Sources"

sources = Dir.glob("src/*.swift").map { |path| group.new_file(path) }

target.add_file_references(sources)

build_settings(project,
  "SWIFT_VERSION" => "$SWIFT_VERSION",
  "ENABLE_BITCODE" => "NO"
)

project.save
EOF

echo "################################"
echo "#### pod install"

cat <<EOF > Podfile
platform :ios, "9.0"
swift_version = "$SWIFT_VERSION"
use_frameworks!

target '$title' do
  pod "Cordova"
end
EOF

pod install
