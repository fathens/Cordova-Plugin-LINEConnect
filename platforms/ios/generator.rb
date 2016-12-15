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

def accessors(clazz)
    keys = clazz.instance_methods
    names = keys.map { |key| key.to_s }
    keys.select { |key|
        key.to_s.match(/^\w+$/) && names.include?("#{key}=")
    }
end

class Pod
    attr_accessor :name, :version, :path, :git, :branch, :tag, :commit

    def initialize(params = {})
        e = params[:element]
        accessors(Pod).each { |key|
            value = params[key] || (e ? e.attributes[key.to_s] : nil)
            send "#{key}=", value
        }
    end

    def or_nil(key, with_prefix = true)
        value = send(key)
        prefix = with_prefix ? ":#{key} => " : ""
        return value ? "#{prefix}'#{value}'" : nil
    end

    def to_s
        args = [
            or_nil(:name, false),
            or_nil(:version, false),
            or_nil(:path),
            or_nil(:git),
            or_nil(:branch),
            or_nil(:tag),
            or_nil(:commit)
        ]
        log "Pod #{args}"
        "pod " + args.select { |a| a != nil }.join(', ')
    end
end

class Podfile
    attr_accessor :ios_version, :swift_version, :pods

    def initialize(xmlFile)
        xml = REXML::Document.new(File.open(xmlFile))
        element = xml.get_elements('//platform[@name="ios"]/podfile').first

        @ios_version = element.attributes['ios_version'] || '10.0'
        @swift_version = element.attributes['swift_version'] || '3.0'
        @pods = element.get_elements('pod').map { |e|
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

podfile = Podfile.new($PROJECT_DIR/'plugin.xml')
podfile.pods.unshift(Pod.new(name: 'Cordova'))

proj = XcodeProject.new($TITLE)
proj.sources_pattern = "src/*.swift"
proj.build_settings = {
  "SWIFT_VERSION" => podfile.swift_version,
  "ENABLE_BITCODE" => "NO"
}

proj.write
podfile.write($TITLE)

log_header "pod install"
system "pod install"
