require 'fileutils'
require 'shellwords'

module GitRepository
    def self.clone_lineadapter(plugin_dir)
        git_clone(
            "https://bitbucket.org/fathens/lineadapter_ios.git",
            plugin_dir/'.tmp'/'LineAdapter-iOS',
            tag: "version/3.2.1",
            username: ENV['BITBUCKET_USERNAME'],
            password: ENV['BITBUCKET_PASSWORD']
        )
    end

    def self.git_clone(url, dir, tag: nil, username: nil, password: nil)
        FileUtils.rm_rf(dir) if dir.exist?
        cred = [username, password].compact.map {|s| s.shellescape }.join(':')
        target_url = cred.empty? ? url : url.sub(/^https:\/\//, "https://#{cred}@")
        target_url = "-b #{tag} #{target_url}" if tag
        system "git clone #{target_url} #{dir}"
    end
end
