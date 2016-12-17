require 'pathname'

class PluginGradle
    attr_accessor :base_dir, :jar_files, :jni_dir

    def initialize(base_dir)
        @base_dir = base_dir
    end

    def write(target_file)
        files_line = @jar_files.map { |x|
            "'#{mk_path(x)}'"
        }.join(', ')

        File.open(target_file, 'w') { |dst|
            dst.puts <<~EOF
            dependencies {
                compile files(#{files_line})
            }
            android {
                sourceSets {
                    main.jniLibs.srcDirs += '#{mk_path(@jni_dir)}'
                }
            }
            EOF
        }
    end

    def mk_path(p)
        p.relative_path_from @base_dir
    end
end
