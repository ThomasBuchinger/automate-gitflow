# frozen_string_literal: true

# Global Methods
module MiqFlow
  include MiqFlow::Settings
  include MiqFlow::Config
  include MiqFlow::GitMethods

  def self.init
    $logger.debug("Using Settings: #{$settings.to_yaml}")

    # prepare directories
    #
    $tmpdir = $settings[:workdir] == 'auto' ? Dir.mktmpdir('miq_import_') : $settings[:workdir]
    Dir.mkdir(File.join($tmpdir, 'repo'))
    Dir.mkdir(File.join($tmpdir, 'import'))
    $logger.debug("Using tmp directory: #{$tmpdir}")
  end

  def self.prepare_repo
    opts = $settings[:git]
    GitMethods.clone_repo(opts) unless opts[:url].nil?
    GitMethods.local_repo(opts) unless opts[:path].nil?
  end

  def self.tear_down
    clean_tmp_dir() if $settings[:clear_tmp]
  end

  def self.clean_tmp_dir
    return if $tmpdir.nil?

    FileUtils.rm_rf(File.join($tmpdir, 'import'))
    FileUtils.rm_rf(File.join($tmpdir, 'repo'))
    FileUtils.rmdir($tmpdir) if Dir["#{$tmpdir}/*"].empty?
  end

  def self.validate(mode=[])
    d = { count: 0, messages: [] }
    validate_git(d) if mode.include?(:git)
    validate_miq(d) if mode.include?(:miq)
    validate_api(d) if mode.include?(:api)

    d[:count].zero? ? true : raise(MiqFlow::ConfigurationError, "Invalid Configuration. #{d[:count]} offenses found.")
  end

  def self.log_problem(data, message='')
    $logger.fatal(message)
    data[:messages] << message
    data[:count] += 1
  end

  def self.validate_api(valid)
    log_problem(valid, 'No ManageIQ API specified') if $settings[:miq][:url].nil?
    log_problem(valid, 'No ManageIQ API password specified') if $settings[:miq][:password].nil?
  end

  def self.validate_miq(valid)
    valid
  end

  def self.validate_ruby(valid)
    # Ruby 2.3 was available since Euwe, this should be fine
    log_problem(valid, 'Ruby > 2.3.0: Hash#dig not available') unless Hash.method_defined?(:dig)
  end

  def self.validate_git(valid)
    log_problem(valid, 'No git repository specified') if $settings[:git][:url].nil? && $settings[:git][:path].nil?
  end

  def self.human_readable_time(timestamp:, now: Time.now) # rubocop:disable Metrics/CyclomaticComplexity
    uptime = (now - timestamp).to_i
    case uptime
    when 0..59 then 'just now'
    when 60..119 then '1 minute ago' # 120 = 2 minutes
    when 120..3540 then (uptime / 60).to_i.to_s + ' minutes ago'
    when 3541..7100 then 'an hour ago' # 3600 = 1 hour
    when 7101..82_800 then ((uptime + 99) / 3600).to_i.to_s + ' hours ago'
    when 82_801..172_000 then '1 day ago' # 86400 = 1 day
    else ((uptime + 800) / 86_400).to_i.to_s + ' days ago'
    end
  end
end
