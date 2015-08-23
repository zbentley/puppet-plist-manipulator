require "acceptance/spec_helper"

# context "when testing harness" do
#   tmpfile = Tempfile.new("harness_test")
#   testpath = tmpfile.path
#   tmpfile.unlink

#   with_manifest("file { '#{testpath}': ensure => 'present' }", "single-file") do
#     it "creates expected file" do
#       expect(file(testpath)).to be_file
#     end
#   end

#   with_manifest("notice(1)", "non-state-changing", :expect_changes => false) {}
#   with_manifest(
#     "fail('#{testpath}')",
#     "compilation-breaking",
#     :expect_changes => false,
#     :compile_failure => testpath, # Compilation failure should contain test file path.
#   ) {}
#   with_manifest(
#     "file { '/dev/null/#{testpath}': ensure => 'present' }",
#     "apply-failing",
#     :apply_failure => testpath,
#     :expect_changes => false
#   ) {}
# end