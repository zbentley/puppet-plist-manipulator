require "acceptance/spec_helper"
# Keep the tempfile variable in a global to prevent it from being destroyed
# when we don't want it to be.
tempfile = ""
def tempfile_manifest(opts)
  tmpfile = Tempfile.new(['com.test', '.plist'], '/Users/zbentley/Library/Preferences')
  plist_file_name = File.basename(tmpfile.path)
  manifest_attrs = "";
  opts.each do |key, value|
    manifest_attrs += "#{key}  =>  #{value},\n"
  end

    manifest = <<END
  plist::item { 'test' :
    #{manifest_attrs}
    domain => '#{plist_file_name}';
  }
END
  return {
    :manifest => manifest,
    :filename => plist_file_name,
    :filepath => tmpfile.path,
  }
end

def write_values(filename, key, values = "")
  describe command("/usr/bin/defaults write #{filename} #{key} -array #{values}"), "can setup file" do
    its(:exit_status) { should be_zero }
    its(:stdout) { should be_empty }
  end
end

def check_values(filename, key, values = [])
  cmd = command("/usr/bin/defaults read #{filename} #{key}")
  it ".plist has expected values" do
    # Discard the first and last (parentheses), trailing commas, and strip whitespace on the rest.
    significantvalues = cmd.stdout.split("\n").map! { |item| item.strip().chomp(",") }
    expect(significantvalues[1...-1]).to eq values
  end
end

# requires homebrew binutils/stat
context "with plist files in ~/Library/Preferences" do

  options = tempfile_manifest(:ensure => "present", :key => "foo", :value => "bar")

  with_manifest(options[:manifest], "non-array item", :compile_failure => /TODO DODO/) do
    pending("not implemented")
  end

  context "with an empty .plist file" do
    options = tempfile_manifest(:type => "array-item", :key => "foo", :value => "bar")
    write_values(options[:filename], "foo")

    with_manifest(options[:manifest], "single array item") do
      check_values(options[:filename], "foo", ["bar"])
    end
  end

  context "with pre-existing .plist file contents" do
    options = tempfile_manifest(:type => "array-item", :key => "foo", :value => "bar")
    write_values(options[:filename], "foo", "foo")

    with_manifest(options[:manifest], "single array item") {
      check_values(options[:filename], "foo", ["bar", "foo"])
    }
  end

  context "with a nonexistent .plist file" do
    options = tempfile_manifest(:type => "array-item", :key => "foo", :value => "bar")
    File.unlink(options[:filepath])

    with_manifest(options[:manifest], "single array item") do
      check_values(options[:filename], "foo", ["bar"])
      describe file(options[:filepath]) do
        it { should be_file }
      end
    end
  end

  # in each write/positional mode:
  # => puts existing keys back
  # => preserves spaces in existing keys
  # => preserves spaces in added keys

end
