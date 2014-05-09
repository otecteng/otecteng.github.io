#!/usr/bin/env ruby
require 'net/http'
require 'net/https'
require 'etc'
require 'fileutils'
require 'timeout'
require 'yaml'
require 'logger'
logger = Logger.new('/etc/puppet/enc.log')
logger.info "hi!"
begin
  require 'json'
rescue LoadError
  begin
    require 'rubygems' rescue nil
    require 'json'
  rescue LoadError => e
    puts "You need the `json` gem to use the Foreman ENC script"
    exit 2
  end
end
SETTINGS = {
  :url          => "http://localhost:3000/puppet_yaml.yaml?node_name=",  # e.g. https://foreman.example.com
  :puppetdir    => "/var/lib/puppet",  # e.g. /var/lib/puppet
  :puppetuser   => "puppet",  # e.g. puppet
  :facts        => false,          # true/false to upload facts
  :timeout      => 30,
  :threads      => nil,
}

def url
  SETTINGS[:url] || raise("Must provide URL - please edit file")
end

def puppetdir
  SETTINGS[:puppetdir] || raise("Must provide puppet base directory - please edit file")
end

def puppetuser
  SETTINGS[:puppetuser] || 'puppet'
end
def tsecs
  SETTINGS[:timeout] || 30
end


#def cache(certname, result)
#  File.open(stat_file(certname), 'w') {|f| f.write(result) }
#end

def read_cache(certname)
  File.read(stat_file(certname))
rescue => e
  raise "Unable to read from Cache file: #{e}"
end

def enc(certname)
  foreman_url      = "#{url}#{certname}"
  uri              = URI.parse(foreman_url)
  req              = Net::HTTP::Get.new(uri.request_uri)
  http             = Net::HTTP.new(uri.host, uri.port)
  res = http.start { |http| http.request(req) }
  raise "Error retrieving node #{certname}: #{res.class}\nCheck Foreman's /var/log/foreman/production.log for more information." unless res.code == "200"
  res.body
end


if __FILE__ == $0 then
  # Setuid to puppet user if we can
  begin
    Process::GID.change_privilege(Etc.getgrnam(puppetuser).gid) unless Etc.getpwuid.name == puppetuser
    Process::UID.change_privilege(Etc.getpwnam(puppetuser).uid) unless Etc.getpwuid.name == puppetuser
    # Facter (in thread_count) tries to read from $HOME, which is still /root after the UID change
    ENV['HOME'] = Etc.getpwnam(puppetuser).dir
  rescue
    $stderr.puts "cannot switch to user #{puppetuser}, continuing as '#{Etc.getpwuid.name}'"
  end

  begin
    logger.info "start enc #{ARGV[0]}"
    no_env = ARGV.delete("--no-environment")
    certname = ARGV[0] || raise("Must provide certname as an argument")
      # query External node
    begin
        result = ""
        timeout(tsecs) do
          result = enc(certname)
          #cache(certname, result)
        end
    rescue TimeoutError, SocketError, Errno::EHOSTUNREACH, Errno::ECONNREFUSED => e
        logger.info "read from server wrong:"
        logger.error e
        p e
        # Read from cache, we got some sort of an error.
        result = read_cache(certname)
    end

    logger.info Time.now
    logger.info result

    if no_env
        require 'yaml'
        yaml = YAML.load(result)
        yaml.delete('environment')
        # Always reset the result to back to clean yaml on our end
        puts yaml.to_yaml.gsub "\"",""
    else
        puts result.gsub "\"",""
    end
  rescue => e
    logger.warn e
    warn e
    exit 1
  end
end

  
