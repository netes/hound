class RubyStyleGuide
  RUBOCOP_CONFIG_FILE = "config/rubocop.yml"

  def initialize(config_content = nil)
    if config_content
      @config = RuboCop::Config.new(
        RuboCop::ConfigLoader.merge(config, YAML.load(config_content)),
        RUBOCOP_CONFIG_FILE
      )
    end
  end

  def violations(file)
    if ignored_file?(file)
      []
    else
      parsed_source = parse_source(file)
      cops = RuboCop::Cop::Cop.all
      team = RuboCop::Cop::Team.new(cops, config, rubocop_options)
      team.inspect_file(parsed_source)
    end
  end

  private

  def ignored_file?(file)
    !file.ruby? || file.removed? || excluded_file?(file)
  end

  def excluded_file?(file)
    config.file_to_exclude?(file.filename)
  end

  def parse_source(file)
    RuboCop::ProcessedSource.new(file.content, file.filename)
  end

  def config
    @config ||= begin
      RuboCop::ConfigLoader.configuration_from_file(RUBOCOP_CONFIG_FILE)
    end
  end

  def rubocop_options
    if config["ShowCopNames"]
      { debug: true }
    end
  end
end
