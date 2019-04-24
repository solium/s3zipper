require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rake/extensiontask"

task :build => :compile

Rake::ExtensionTask.new("s3_zipper") do |ext|
  ext.lib_dir = "lib/s3_zipper"
end

task :default => [:clobber, :compile, :spec]
