#! /usr/bin/env ruby

require 'open3'
require 'set'

CONFIG = {
  'dirs' => {
    File.expand_path(File.dirname(__FILE__)) + '/' => '/home/tirsen/web/public/playtube'
  },
  'excludes' => [
    'autorsync.rb',
    '*.iml',
    'prod',
    'data',
    'guides',
    'working_dir',
    '.idea',
    '.svn'
  ],
  'host' => 'tirsen.com'
}

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

CONFIG['dirs'].each do |dir, dest|
  puts "auto-rsyncing #{dir} to #{CONFIG['host']}:#{dest}"
end

def rsync(dir, dest)
  excludes = CONFIG['excludes'].collect {|e| "--exclude=#{e}" }.join(' ')
  "rsync -avz --no-perms #{dir} #{CONFIG['host']}:#{dest} #{excludes}"
end

# Start off by rscyncing everything.
CONFIG['dirs'].each do |dir, dest|
  $cmds.add(rsync(dir, dest))
end

# Then rsync only when something changes.
Open3.popen3('sudo /Users/tirsen/bin/fslogger') do |stdin, stdout, stderr, wait_thr|
  stdout.each_line do |line|
    CONFIG['dirs'].each do |dir, dest|
      if line =~ /^ *FSE_ARG_STRING.*string = #{dir}(.*)$/
        # TODO do a smaller rsync by using $1
        puts "file changed #{$1}"
        $cmds.add(rsync(dir, dest))
      end
    end
  end
end
