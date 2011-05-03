#! /usr/bin/env ruby

require 'rubygems'

gem 'ruby-fsevent'
require 'fsevent'

require 'open3'
require 'set'
require 'yaml'

def usage()
  $stderr.puts " autorsync.rb <config file>"
end

if ARGV.length != 1
  usage()
  exit(-1)
end

class AutoRsyncer < FSEvent
  def initialize(config)
    super()
    @config = config
  end

  def on_change(directories)
    dirs = Set.new
    @config['dirs'].each do |entry|
      directories.each do |d|
        if d.start_with?(entry['from'])
          dirs.add(entry)
        end
      end
    end
    dirs.each do |d|
      rsync(d)
    end
  end

  def start
    self.watch_directories(@config['dirs'].collect{|d| d['from']})

    @config['dirs'].each do |entry|
      puts "auto-rsyncing #{entry['from']} to #{entry['to']}"
    end

    # Start off by rsyncing everything.
    @config['dirs'].each do |entry|
      rsync(entry)
    end

    # Start the watching
    super
  end

  def rsync(entry)
    excludes = @config['excludes'].collect {|e| "--exclude=#{e}" }.join(' ')
    cmd = "rsync -avz --no-perms #{entry['from']} #{entry['to']} #{excludes}"
    puts cmd
    system(cmd)
  end
end

AutoRsyncer.new(YAML.load(File.open(ARGV[0]))).start
