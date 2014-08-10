class FileViolation < Struct.new(:file, :line_violations)
  def filename
    file.filename
  end

  def commit
    file.commit
  end
end
