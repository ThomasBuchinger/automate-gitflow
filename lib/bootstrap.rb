require 'rugged'
require 'tmpdir'
require 'logger'

lib_dir = __dir__
$LOAD_PATH << lib_dir
require 'feature.rb'
require 'gitflow.rb'
require 'miq/provider_docker.rb'
require 'miq/provider_local.rb'
require 'miq/provider_noop.rb'

$default_opts = { :clear_tmp => true }
$default_opts[:feature_defaults] = {}
$default_opts[:git_opts] = {}
require_relative '../custom.rb' if File.file?(File.expand_path(File.join(lib_dir, '..', 'custom.rb')))
GitFlow.process_environment_variables()
$default_opts.freeze()
GitFlow.validate() ? true : exit(1)
