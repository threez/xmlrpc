require 'spec/rake/spectask'
require 'rake/rdoctask'

desc "create rdoc"
Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.rdoc_files.include("README", "lib/**/*.rb")
end

namespace :test do
  desc "run all specifications"
  Spec::Rake::SpecTask.new('spec') do |t|
    rm_f "doc/coverage"
    mkdir_p "doc/coverage"
    t.spec_files = FileList['spec/**/*.rb']
    t.rcov = true
    t.rcov_dir = 'doc/coverage'
    t.rcov_opts = ['--exclude', 'spec']
  end
end


