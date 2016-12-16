require 'pathname'
require 'rexml/document'
require 'xcodeproj'

def log(msg)
    puts msg
end

def log_header(msg)
    log "################################"
    log "#### #{msg}"
end

class ElementStruct
    def self.accessors(clazz)
        keys = clazz.instance_methods
        names = keys.map { |key| key.to_s }
        keys.select { |key|
            key.to_s.match(/^\w+$/) && names.include?("#{key}=")
        }
    end

    def initialize(params = {})
        @element = params[:element]
        ElementStruct.accessors(self.class).each { |key|
            value = params[key] || attributes(key.to_s)
            send "#{key}=", value
        }
    end

    def attributes(name)
        @element ? @element.attributes[name] : nil
    end

    def sub_elements(xpath)
        @element ? @element.get_elements(xpath) : []
    end
end

class BridgingHeader < ElementStruct
    attr_accessor :import

    def initialize(params = {})
        super
    end
end

class Pod < ElementStruct
    attr_accessor :name, :version, :path, :git, :branch, :tag, :commit, :podspec, :subspecs

    def initialize(params = {})
        super
    end

    def bridging_headers
        @bridging_headers ||= sub_elements('bridging-header').map { |e|
            BridgingHeader.new(element: e)
        }
    end

    def to_s
        args = [
            or_nil(:name, false),
            or_nil(:version, false),
            or_nil(:path),
            or_nil(:git),
            or_nil(:branch),
            or_nil(:tag),
            or_nil(:commit),
            or_nil(:podspec),
            @subspecs ? ":subspecs => [#{@subspecs.split(',').map {|x| "'#{x.strip}'"}.join(', ')}]" : nil
        ]
        log "Pod #{args}"
        "pod " + args.compact.join(', ')
    end

    private

    def or_nil(key, with_prefix = true)
        value = send(key)
        prefix = with_prefix ? ":#{key} => " : ""
        return value ? "#{prefix}'#{value}'" : nil
    end
end

class Podfile < ElementStruct
    attr_accessor :ios_version, :swift_version

    def initialize(params = {})
        super
    end

    def pods
        @pods ||= sub_elements('pod').map { |e|
            Pod.new(element: e)
        }
    end

    def write(target_name)
        log_header "Write Podfile"

        target = $PLATFORM_DIR/'Podfile'
        File.open(target, "w") { |dst|
            dst.puts "platform :ios,'#{@ios_version}'"
            dst.puts "swift_version = #{@swift_version}"
            dst.puts "use_frameworks!"
            dst.puts()
            dst.puts "target '#{target_name}' do"
            dst.puts @pods.map { |pod|
                "    #{pod}"
            }
            dst.puts "end"
        }
    end
end

class BridgingHeaderFile
    def initialize(all)
        @headers = all.uniq { |x| x.import }
    end

    def write(file)
        File.open(file, "w") { |dst|
            dst.puts @headers.map { |header|
                "#import <#{header.import}>"
            }
        }
    end
end

class XcodeProject
    attr_accessor :build_settings, :sources_pattern

    def initialize(title)
        @title = title
        @project = Xcodeproj::Project.new "#{@title}.xcodeproj"
        @target = @project.new_target(:framework, @title, :ios)
        @project.recreate_user_schemes
        @build_settings = {}
        @sources_pattern = "*.swift"
    end

    def write
        log_header "Write #{@title}.xcodeproj"

        @project.targets.each do |target|
            group = @project.new_group "Sources"
            sources = Dir.glob(@sources_pattern).map { |path|
                log "Adding source to #{target.name}: #{path}"
                group.new_file(path)
            }
            target.add_file_references(sources)

            target.build_configurations.each do |conf|
                @build_settings.each do |key, value|
                    log "Set #{target.name}(#{conf.name}) #{key}=#{value}"
                    conf.build_settings[key] = value
                end
            end
        end

        @project.save
    end
end

$PLATFORM_DIR = Pathname($0).realpath.dirname
$PROJECT_DIR = $PLATFORM_DIR.dirname.dirname
$TITLE = "CordovaPlugin_#{$PROJECT_DIR.basename}"

plugin_xml = REXML::Document.new(File.open($PROJECT_DIR/'plugin.xml'))

podfile = Podfile.new(element: plugin_xml.get_elements('//platform[@name="ios"]/podfile').first)
podfile.pods.unshift(Pod.new(name: 'Cordova'))

bridge_file = $PLATFORM_DIR/"Bridging-Header.h"
bridge = BridgingHeaderFile.new(podfile.pods.map {|p| p.bridging_headers }.flatten)
bridge.write(bridge_file)

proj = XcodeProject.new($TITLE)
proj.sources_pattern = "src/*.swift"
proj.build_settings = {
    "SWIFT_OBJC_BRIDGING_HEADER" => bridge_file.relative_path_from($PLATFORM_DIR),
    "SWIFT_VERSION" => podfile.swift_version,
    "ENABLE_BITCODE" => "NO"
}

proj.write
podfile.write($TITLE)

log_header "pod install"
system "pod install"