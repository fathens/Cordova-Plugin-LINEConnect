require 'pathname'
require 'fileutils'
require_relative '../../lib/git_repository'

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

def download_cordova_src(target_dir)
    tmp_dir = $PLATFORM_DIR/'.tmp'
    GitRepository.git_clone('https://github.com/apache/cordova-android.git', tmp_dir)
    (tmp_dir/'framework'/'src').rename(target_dir)
    FileUtils.rm_rf(tmp_dir)
end

def write_build_gradle
    File.open('bundle.gradle', 'w') { |dst|
        dst.puts <<~EOF
        buildscript {
            repositories {
                mavenCentral()
            }
            dependencies {
                classpath 'com.android.tools.build:gradle:1.+'
                classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:1.+"
            }
        }
        apply plugin: 'com.android.application'
        apply plugin: 'kotlin-android'

        repositories {
            mavenCentral()
        }

        apply from: "plugin.gradle"

        dependencies {
            compile "org.jetbrains.kotlin:kotlin-stdlib:1.+"
        }

        android {
            compileSdkVersion 'android-21'
            buildToolsVersion '25.0.2'
            sourceSets {
                main.java {
                    srcDirs += '.cordova'
                    srcDirs += 'src/main/kotlin'
                }
            }
        }
        EOF
    }
end

download_cordova_src($PLATFORM_DIR/'.cordova')
write_build_gradle

log "Generating project done"
log "Open by AndroidStudio. Thank you."