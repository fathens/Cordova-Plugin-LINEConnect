require 'pathname'
require_relative '../../lib/git_repository'
require_relative '../../lib/xcode_project'
require_relative '../../lib/podfile'

def log(msg)
    puts msg
end

def log_header(msg)
    log "################################"
    log "#### #{msg}"
end

$PLATFORM_DIR = Pathname($0).realpath.dirname
$PROJECT_DIR = $PLATFORM_DIR.dirname.dirname

ENV['PLUGIN_DIR'] = $PROJECT_DIR.to_s

plugin_xml = REXML::Document.new(File.open($PROJECT_DIR/'plugin.xml'))

podfile = Podfile.new(element: plugin_xml.get_elements('//platform[@name="ios"]/podfile').first)
podfile.pods.unshift(Pod.new(name: 'Cordova'))
podfile.swift_version ||= '3.0'
podfile.ios_version ||= '10.0'

bridge = BridgingHeaderFile.new(podfile.pods.map {|p| p.bridging_headers }.flatten)
bridge_file = bridge.write($PLATFORM_DIR/".Bridging-Header.h")

proj = XcodeProject.new
proj.sources_pattern = "src/*.swift"
proj.build_settings = {
    "SWIFT_OBJC_BRIDGING_HEADER" => bridge_file ? bridge_file.relative_path_from($PLATFORM_DIR) : nil,
    "SWIFT_VERSION" => podfile.swift_version,
    "ENABLE_BITCODE" => "NO"
}

GitRepository.lineadapter_ios($PROJECT_DIR, '3.2.1').git_clone
target_name = proj.write("CordovaPlugin_#{$PROJECT_DIR.basename}")
podfile.write(target_name)

log_header "pod install"
system "pod install"
