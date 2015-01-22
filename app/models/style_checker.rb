# Filters files to reviewable subset.
# Builds style guide based on file extension.
# Delegates to style guide for line violations.
class StyleChecker
  def initialize(commit, config)
    @commit = commit
    @config = config
    @style_guides = {}
  end

  def violations
    @violations ||= Violations.new.push(*violations_in_checked_files).to_a
  end

  private

  attr_reader :commit, :style_guides, :config

  def violations_in_checked_files
    files_to_check.flat_map do |file|
      style_guide(file.filename).violations_in_file(file)
    end
  end

  def files_to_check
    commit.files.select do |file|
      file_style_guide = style_guide(file.filename)
      !file.removed? && file_style_guide.enabled? && file_style_guide.file_included?(file)
    end
  end

  def style_guide(filename)
    style_guide_class = style_guide_class(filename)
    style_guides[style_guide_class] ||= style_guide_class.new(
      config,
      commit.repository_owner
    )
  end

  def style_guide_class(filename)
    case filename
    when /.+\.rb\z/
      StyleGuide::Ruby
    when /.+\.coffee(\.js)?\z/
      StyleGuide::CoffeeScript
    when /.+\.js\z/
      StyleGuide::JavaScript
    when /.+\.scss\z/
      StyleGuide::Scss
    else
      StyleGuide::Unsupported
    end
  end
end
