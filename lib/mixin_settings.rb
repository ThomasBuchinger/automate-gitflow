# frozen_string_literal: true

module GitFlow
  # This mixin handles configuration updates
  # Every update_* method only modifies he config if a
  # reasonable value is provided
  module Settings
    def self.set_defaults
      update_log_level(:info)
      update_clear_tmp('yes')
      update_workdir('auto')

      update_miq_api(nil, 'admin', nil)
    end

    def self.process_environment_variables
      # Git params
      update_git(ENV['GIT_URL'], ENV['GIT_PATH'], ENV['GIT_USER'], ENV['GIT_PASSWORD'])

      # MIQ params
      update_miq_api(ENV['MIQ_URL'], ENV['MIQ_USER'], ENV['MIQ_PASSWORD'])

      # Misc
      update_log_level(:debug) if truthy(ENV.fetch('VERBOSE', 'no'))
      update_log_level(:warn)  if truthy(ENV.fetch('QUIET', 'no'))
      update_clear_tmp(ENV['CLEAR_TMP'])
    end

    def self.process_config_file(path) # rubocop:disable Metrics/AbcSize
      return unless path.kind_of?(String) && File.file?(path)

      $logger.info("Processing config file: #{path}")
      conf = YAML.load_file(path) || {}
      git_conf = conf['git'] || {}
      miq_conf = conf['miq'] || {}

      update_log_level(conf['log_level'])
      update_clear_tmp(conf['clear_tmp'])
      update_git(git_conf['url'], git_conf['path'], git_conf['user'], git_conf['password'])
      update_miq_api(miq_conf['url'], miq_conf['user'], miq_conf['password'])
      update_workdir(conf['workdir'])
    end

    def self.update_log_level(level)
      return if level.nil?

      log_level = {
        debug: Logger::DEBUG,
        info: Logger::INFO,
        warn: Logger::WARN,
        error: Logger::ERROR,
        fatal: Logger::FATAL
      }
      return unless log_level.key?(level.to_sym)

      # Create logger if nit already creates
      $logger = Logger.new(STDERR) if $logger.nil?
      $logger.level = log_level[level.to_sym]

      # This is just for ducomentation, when dumping the config
      $settings[:log_level] = level
    end

    def self.update_clear_tmp(clear_flag)
      return unless truthy(clear_flag) || falsey(clear_flag)

      $settings[:clear_tmp] = truthy(clear_flag)
    end

    def self.update_git(url, path, user, password)
      $settings[:git][:url]  = url  unless url.nil?
      $settings[:git][:path] = path unless path.nil?
      $settings[:git][:user] = user unless user.nil?
      $settings[:git][:password] = password unless password.nil?
    end

    def self.update_workdir(dir)
      return if dir.nil?

      return if dir != 'auto' && !File.directory?(dir)

      $settings[:workdir] = dir
    end

    def self.update_miq_api(url, user, password)
      $settings[:miq][:url]      = url unless url.nil?
      $settings[:miq][:user]     = user unless user.nil?
      $settings[:miq][:password] = password unless password.nil?
    end

    def self.truthy(value)
      true_values = %w[true TRUE True yes YES Yes t T y Y 1]
      true_values.include?(value.to_s)
    end

    def self.falsey(value)
      false_values = %w[false FALSE False no NO No f F n N 0]
      false_values.include?(value.to_s)
    end
  end
end
