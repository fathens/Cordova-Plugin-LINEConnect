require 'pathname'
require 'fileutils'
require_relative '../../lib/git_repository'
require_relative '../../lib/plugin_gradle'

def log(msg)
    puts msg
end

def log_header(msg)
    log "################################"
    log "#### #{msg}"
end

$PLATFORM_DIR = Pathname($0).realpath.dirname
$PLUGIN_DIR = $PLATFORM_DIR.dirname.dirname

ENV['PLUGIN_DIR'] = $PLUGIN_DIR.to_s

def write_build_gradle(cordova_srcdir)
    File.open('build.gradle', 'w') { |dst|
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
                    srcDirs += '#{cordova_srcdir.relative_path_from $PLATFORM_DIR}'
                    srcDirs += 'src/main/kotlin'
                }
            }
        }
        EOF
    }
end

def write_plugin_gradle
    repo_dir = GitRepository.lineadapter_android($PLUGIN_DIR, '3.1.21').git_clone

    gradle = PluginGradle.new($PLATFORM_DIR)
    gradle.jar_files = Pathname.glob(repo_dir/'*.jar')
    gradle.jni_dir = repo_dir/'libs'
    gradle.write
end

cordova_srcdir = GitRepository.new(
    'https://github.com/apache/cordova-android.git', $PLUGIN_DIR
).git_clone/'framework'/'src'
write_build_gradle(cordova_srcdir)
write_plugin_gradle

log "Generating project done"
log "Open by AndroidStudio. Thank you."
