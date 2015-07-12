require "acceptance/spec_helper"


context "with a plist file in ~/Library/Preferences" do
  tmpfile = Tempfile.new(['com.test', '.plist'], '/Users/zbentley/Library/Preferences')
  testpath = File.basename(tmpfile)
  manifest = <<END
  plist::item { 'test' :
    ensure => 'present',
    domain => '#{testpath}',
    key => 'foo',
    value => 'bar';
  }
END

  with_manifest(manifest, false, :compile_failure => /TODO DODO/) do
    pending("not implemented")
  end
end
