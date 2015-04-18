require "acceptance/spec_helper"

context "when testing harness" do
  tmpfile = Tempfile.new("harness_test")
  testpath = tmpfile.path
  tmpfile.unlink

  with_manifest "empty", "file { '#{testpath}': ensure => 'present' }", :expect_changes => 1 do
    it "creates expected file" do
      expect(file(testpath)).to be_file
    end
  end
end