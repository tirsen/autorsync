#! /usr/bin/env ruby

require 'open3'
require 'set'
require 'yaml'

FSLOGGER=File.join(File.expand_path(File.dirname(__FILE__)), 'fslogger')

def usage()
  $stderr.puts " autorsync.rb <config file>"
end

if ARGV.length != 1
  usage()
end

CONFIG = YAML.load(File.open(ARGV[0]))

$cmds = Set.new

Thread.new do
  while true
    sleep(3)
    if not $cmds.empty?
      cmds_to_run = $cmds
      $cmds = Set.new
      cmds_to_run.each do |cmd|
        puts cmd
        system(cmd)
      end
    end
  end
end

CONFIG['dirs'].each do |entry|
  puts "auto-rsyncing #{entry['from']} to #{entry['to']}"
end

def rsync(entry)
  excludes = CONFIG['excludes'].collect {|e| "--exclude=#{e}" }.join(' ')
  "rsync -avz --no-perms #{entry['from']} #{entry['to']} #{excludes}"
end

# Start off by rscyncing everything.
CONFIG['dirs'].each do |entry|
  $cmds.add(rsync(entry))
end

# Then rsync only when something changes.
Open3.popen3("sudo #{FSLOGGER}") do |stdin, stdout, stderr, wait_thr|
  stdout.each_line do |line|
    CONFIG['dirs'].each do |entry|
      if line =~ /^ *FSE_ARG_STRING.*string = #{entry['from']}(.*)$/
        # TODO do a smaller rsync by using $1
        puts "file changed #{$1}"
        $cmds.add(rsync(entry))
      end
    end
  end
end
