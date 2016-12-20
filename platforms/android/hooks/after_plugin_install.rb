#!/usr/bin/env ruby

require 'pathname'
require 'fetch_local_lib'

def rewrite_gradle(fileSrc)
    fileDst = "#{fileSrc}.tmp"
        open(fileSrc, 'r') { |src|
            open(fileDst, 'w') { |dst|
                src.each_line { |line|
                    dst.puts line.gsub(/\$\{(.+?)\}/) {
                        ENV[$1] || $1
                    }
                }
            }
        }
    File.rename(fileDst, fileSrc)
end

$PLUGIN_PLATFORM_DIR = Pathname(ENV['CORDOVA_HOOK'] || $0).realpath.dirname.dirname
$PLUGIN_DIR = $PLUGIN_PLATFORM_DIR.dirname.dirname
ENV['PLUGIN_DIR'] = $PLUGIN_DIR.to_s

FetchLocalLib::Repo.bitbucket($PLUGIN_DIR, "lineadapter_android", tag: "version/3.1.21").git_clone
rewrite_gradle $PLUGIN_PLATFORM_DIR/'plugin.gradle'
