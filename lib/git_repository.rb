require 'fileutils'
require 'shellwords'

module GitRepository
    def self.clone_lineadapter_ios(plugin_dir, version)
        clone_bitbucket("lineadapter_ios",
            plugin_dir/'.tmp'/'LineAdapter-iOS',
            "version/#{version}"
        )
    end

    def self.clone_lineadapter_android(target_dir, version)
        clone_bitbucket("lineadapter_android",
            target_dir,
            "version/#{version}"
        )
    end

    def self.clone_bitbucket(owner, name, dir, tag)
        git_clone("https://bitbucket.org/fathens/#{name}.git", dir, tag: tag,
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
        return dir
    end
end
