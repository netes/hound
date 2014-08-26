require "coffeelint"
require "rubocop"
require "fast_spec_helper"
require "active_support/core_ext/object/try"
require "active_support/core_ext/string/inflections"
require "app/models/ruby_style_guide"
require "app/models/coffee_script_style_guide"
require "app/models/unknown_style_guide"
require "app/models/style_checker"
require "app/models/file_violation"
require "app/models/line_violation"

describe StyleChecker, "#violations" do
  it "returns a collection of files with style violations" do
    modified_file1 = stub_modified_file("good.rb", "def good; end", "Ruby")
    modified_file2 = stub_modified_file(
      "bad.rb", "def bad( a ); a; end  ", "Ruby"
    )
    expected_line_violation = LineViolation.new(
      modified_file2.modified_line_at,
      [
        "Space inside parentheses detected.", 
        "Trailing whitespace detected.",
      ]
    )
    config = "Style/EndOfLine:\n  Enabled: false"

    style_checker = StyleChecker.new(
      [modified_file1, modified_file2],
      config
    )

    expect(style_checker.violations).to eq [
      FileViolation.new(modified_file2, [expected_line_violation]),
    ]
  end

  it "returns a collection of files with style violations" do
    modified_file1 = stub_modified_file("good.coffee", "a = 7", "CoffeeScript")
    modified_file = stub_modified_file("bad.coffee", "1" * 81, "CoffeeScript")

    expected_line_violation = LineViolation.new(
      modified_file.modified_line_at,
      ["Line exceeds maximum allowed length"]
    )

    style_checker = StyleChecker.new(
      [modified_file1, modified_file]
    )

    expect(style_checker.violations).to eq [
      FileViolation.new(modified_file, [expected_line_violation])
    ]
  end

  it "gracefully ignores files of an unknown language" do
    modified_file = stub_modified_file("style.css", "body {}", "Unknown")
    style_checker = StyleChecker.new([modified_file])

    expect(style_checker.violations).to eq([])
  end

  it "ignores disabled languages" do
    coffee_file = stub_modified_file("bad.coffee", "1" * 81, "CoffeeScript")
    config = "Style/EndOfLine:\n  Enabled: false\nCoffeeScript:\n Enabled: false"

    style_checker = StyleChecker.new([coffee_file], config)

    expect(style_checker.violations).to be_empty
  end

  private

  def stub_modified_file(filename, contents, language)
    formatted_contents = "#{contents}\n"
    double(
      :modified_file,
      filename: filename,
      content: formatted_contents,
      ruby?: language == "Ruby",
      coffeescript?: language == "CoffeeScript",
      language: language,
      removed?: false,
      relevant_line?: true,
      modified_line_at: 1
    )
  end
end
