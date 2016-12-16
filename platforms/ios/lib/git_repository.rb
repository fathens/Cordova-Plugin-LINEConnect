require 'fileutils'
require 'shellwords'

module GitRepository
    def self.clone_lineadapter(plugin_dir)
        git_clone(
            "https://bitbucket.org/fathens/lineadapter_ios.git",
            "version/3.2.1",
            ENV['BITBUCKET_USERNAME'],
            ENV['BITBUCKET_PASSWORD'],
            plugin_dir/'.tmp'/'LineAdapter-iOS'
        )
    end

    def self.git_clone(url, tag, username, password, dir)
        FileUtils.rm_rf(dir) if dir.exist?
        cred = [username, password].map {|s| s.shellescape }.join(':')
        target_url = url.sub(/^https:\/\//, "https://#{cred}@")
        system "git clone #{target_url} #{dir}"
        Dir.chdir(dir) {
            system "git checkout #{tag}"
        }
    end
end
