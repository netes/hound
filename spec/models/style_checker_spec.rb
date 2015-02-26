require "spec_helper"

describe StyleChecker, "#violations" do
  it "returns a collection of computed violations" do
    stylish_file = stub_commit_file("good.rb", "def good; end")
    violated_file = stub_commit_file("bad.rb", "def bad( a ); a; end  ")
    commit = stub_commit(files: [stylish_file, violated_file])
    expected_violations =
      ['Unnecessary spacing detected.', 'Space inside parentheses detected.', 'Trailing whitespace detected.']

    violation_messages = StyleChecker.new(commit, stub_repo_config).violations.
      flat_map(&:messages)

    expect(violation_messages).to eq expected_violations
  end

  context "for a Ruby file" do
    context "with style violations" do
      it "returns violations" do
        file = stub_commit_file("ruby.rb", "puts 123    ")
        commit = stub_commit(files: [file])

        violations = StyleChecker.new(commit, stub_repo_config).violations
        messages = violations.flat_map(&:messages)
        expected_violations = ["Unnecessary spacing detected.",
                               "Trailing whitespace detected."]

        expect(messages).to eq expected_violations
      end
    end

    context "with style violation on unchanged line" do
      it "returns no violations" do
        file = stub_commit_file("foo.rb", "'wrong quotes'", UnchangedLine.new)
        commit = stub_commit(files: [file])

        violations = StyleChecker.new(commit, stub_repo_config).violations

        expect(violations.count).to eq 0
      end
    end

    context "without style violations" do
      it "returns no violations" do
        file = stub_commit_file("ruby.rb", "puts 123")
        commit = stub_commit(files: [file])

        violations = StyleChecker.new(commit, stub_repo_config).violations
        messages = violations.flat_map(&:messages)

        expect(messages).to be_empty
      end
    end
  end

  context "for a CoffeeScript file" do
    it "is processed with a coffee.js extension" do
      file = stub_commit_file("test.coffee.js", "foo ->")
      commit = stub_commit(files: [file])
      style_checker = StyleChecker.new(commit, stub_repo_config)
      allow(RepoConfig).to receive(:new).and_return(stub_repo_config)

      violations = style_checker.violations
      messages = violations.flat_map(&:messages)

      expect(messages).to eq ["Empty function"]
    end

    context "with violations" do
      context "with CoffeeScript enabled" do
        it "returns violations" do
          config = <<-YAML.strip_heredoc
            coffee_script:
              enabled: true
          YAML
          file = stub_commit_file("test.coffee", "foo: ->")
          commit = stub_commit(
            files: [file],
            file_content: config
          )

          violations = StyleChecker.new(commit, stub_repo_config).violations
          messages = violations.flat_map(&:messages)

          expect(messages).to eq ["Empty function"]
        end
      end

      context "with CoffeeScript disabled" do
        it "returns no violations" do
          config = stub_repo_config(coffee_script: { enabled: false })
          file = stub_commit_file("test.coffee", "alert 'Hello World'")
          commit = stub_commit(files: [file])

          violations = StyleChecker.new(commit, config).violations

          expect(violations).to be_empty
        end
      end
    end

    context "without violations" do
      context "with CoffeeScript enabled" do
        it "returns no violations" do
          config = stub_repo_config(coffee_script: { enabled: true })
          file = stub_commit_file("test.coffee", "alert('Hello World')")
          commit = stub_commit(files: [file])

          violations = StyleChecker.new(commit, config).violations

          expect(violations).to be_empty
        end
      end
    end
  end

  context "for a JavaScript file" do
    context "with violations" do
      context "with JavaScript enabled" do
        it "returns violations" do
          config = stub_repo_config(java_script: { enabled: true })
          file = stub_commit_file("test.js", "var test = 'test'")
          commit = stub_commit(files: [file])

          violations = StyleChecker.new(commit, config).violations
          messages = violations.flat_map(&:messages)

          expect(messages).to include "Missing semicolon."
        end
      end

      context "with JavaScript disabled" do
        it "returns no violations" do
          config = stub_repo_config(java_script: { enabled: false })
          file = stub_commit_file("test.js", "var test = 'test'")
          commit = stub_commit(files: [file])

          violations = StyleChecker.new(commit, config).violations

          expect(violations).to be_empty
        end
      end
    end

    context "without violations" do
      context "with JavaScript enabled" do
        it "returns no violations" do
          config = stub_repo_config(java_script: { enabled: true })
          file = stub_commit_file("test.js", "var test = 'test';")
          commit = stub_commit(files: [file])

          violations = StyleChecker.new(commit, config).violations
          messages = violations.flat_map(&:messages)

          expect(messages).not_to include "Missing semicolon."
        end
      end
    end

    context "an excluded file" do
      it "returns no violations" do
        config = stub_repo_config(java_script: { enabled: true, ignore_file: '.jshintignore' }, ignored_files: ["test.js"])
        file = stub_commit_file("test.js", "var test = 'test'")
        commit = stub_commit(files: [file])

        violations = StyleChecker.new(commit, config).violations

        expect(violations).to be_empty
      end
    end
  end

  context "for a SCSS file" do
    context "with violations" do
      context "with SCSS enabled" do
        it "returns violations" do
          file = stub_commit_file(
            "test.scss",
            ".table p.inner table td { background: red; }"
          )
          commit = stub_commit(files: [file])

          violations = StyleChecker.new(commit, scss_enabled_config).violations
          messages = violations.flat_map(&:messages)

          expect(messages).to include(
            "Selector should have depth of applicability no greater than 3, but was 4"
          )
        end
      end

      context "with SCSS disabled" do
        it "returns no violations" do
          file = stub_commit_file(
            "test.scss",
            ".table p.inner table td { background: red; }"
          )
          commit = stub_commit(files: [file])

          violations = StyleChecker.new(commit, scss_disabled_config).violations

          expect(violations).to be_empty
        end
      end
    end

    context "without violations" do
      context "with SCSS enabled" do
        it "returns no violations" do
          file = stub_commit_file("test.scss", "table td { color: green; }")
          commit = stub_commit(files: [file])

          violations = StyleChecker.new(commit, scss_enabled_config).violations
          messages = violations.flat_map(&:messages)

          expect(messages).not_to include(
            "Selector should have depth of applicability no greater than 3"
          )
        end
      end
    end
  end

  context "with unsupported file type" do
    it "uses unsupported style guide" do
      file = stub_commit_file("fortran.f", %{PRINT *, "Hello World!"\nEND})
      commit = stub_commit(files: [file])

      violations = StyleChecker.new(commit, stub_repo_config).violations

      expect(violations).to eq []
    end
  end

  context "a removed file" do
    it "does not return a violation for the file" do
      file = stub_commit_file("ruby.rb", "puts 123    ", removed: true)
      commit = stub_commit(files: [file])

      violations = StyleChecker.new(commit, stub_repo_config).violations
      messages = violations.flat_map(&:messages)

      expect(messages).to eq []
    end
  end

  private

  def stub_commit(file_contents: {}, **options)
    defaults = {
      file_content: "",
      repository_owner_name: "some_org",
      files: []
    }

    commit = double("PullRequest", defaults.merge(options))

    file_contents.each do |filename, file_content|
      allow(commit).to receive(:file_content).
        with(filename).and_return(file_content)
    end
    commit
  end

  def stub_commit_file(filename, contents, line = nil, removed: false)
    line ||= Line.new(content: "foo", number: 1, patch_position: 2)
    formatted_contents = "#{contents}\n"
    double(
      filename.split(".").first,
      filename: filename,
      content: formatted_contents,
      removed?: removed,
      line_at: line,
    )
  end

  class DummyConfig < Struct.new(:config)
    def for key
      config[key.to_sym] || {}
    end

    def enabled_for? key
      self.for(key).fetch(:enabled){ true }
    end

    def ignored_javascript_files
      config.fetch(:ignored_files){ [] }
    end
  end

  def stub_repo_config(options = {})
    DummyConfig.new(options)
  end

  def scss_enabled_config
    stub_repo_config(scss: { enabled: true })
  end

  def scss_disabled_config
    stub_repo_config(scss: { enabled: false })
  end
end
