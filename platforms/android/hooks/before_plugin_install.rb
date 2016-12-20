#!/usr/bin/env ruby

require 'pathname'
require 'fetch_local_lib'

def rewrite_gradle(file_dst)
    file_src = "#{file_dst}.template"
    open(file_src, 'r') { |src|
        open(file_dst, 'w') { |dst|
            src.each_line { |line|
                dst.puts line.gsub(/\$\{(.+?)\}/) {
                    ENV[$1] || $1
                }
            }
        }
    }
end

def fetch_lineadapter(plugin_dir)
    ENV['PLUGIN_DIR'] = plugin_dir.to_s
    FetchLocalLib::Repo.bitbucket(plugin_dir, "lineadapter_android", tag: "version/3.1.21").git_clone
    rewrite_gradle plugin_dir/'platforms'/'android'/'plugin.gradle'
end

if $0 == __FILE__
    fetch_lineadapter Pathname(ENV['CORDOVA_HOOK'] || $0).realpath.dirname.dirname.dirname.dirname
end
