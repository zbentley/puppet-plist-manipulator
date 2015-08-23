require "acceptance/spec_helper"
# Keep the tempfile variables in a global to prevent them from being destroyed
# when we don't want them to be.
$tempfiles = []
def tempfile_manifest(opts)
  tmpfile = Tempfile.new(['com.test', '.plist'], '/Users/zbentley/Library/Preferences')
  $tempfiles.push(tmpfile)
  plist_file_name = File.basename(tmpfile.path)
  manifest_attrs = "";
  opts.each do |key, value|
    manifest_attrs += "#{key}  =>  '#{value}',\n"
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
  it "can set up file" do
    cmd = command("/usr/bin/defaults write #{filename} #{key} -array #{values}")
    expect(cmd.exit_status).to be_zero
    expect(cmd.stdout).to be_empty
  end
end

def check_values(filename, key, values = [])
  cmd = command("/usr/bin/defaults read #{filename} #{key}")
  it ".plist has expected values" do
    # Discard the first and last (parentheses), trailing commas, and strip whitespace on the rest.
    significantvalues = cmd.stdout.split("\n").map! do |item|
      item.strip().chomp(",")
    end
    expect(significantvalues[1...-1]).to eq values
  end
end

context "with plist files in ~/Library/Preferences" do

  context "with non-array item" do
    options = tempfile_manifest(:ensure => "present", :key => "foo", :value => "bar")

    with_manifest(options[:manifest], "scalar item", :compile_failure => /TODO DODO/) do
      pending("not implemented")
    end
  end


  context "with an empty .plist file" do
    options = tempfile_manifest(:type => "array-item", :key => "foo", :value => "bar")
    write_values(options[:filename], "foo")

    with_manifest(options[:manifest], "single array item") do
      check_values(options[:filename], "foo", ["bar"])
    end
  end

  context "when prepending a single value" do
    options = tempfile_manifest(:type => "array-item", :key => "foo", :value => "bar")
    write_values(options[:filename], "foo", "foo")

    with_manifest(options[:manifest], "single array item") {
      check_values(options[:filename], "foo", ["bar", "foo"])
    }
  end

  context "with existing elements containing spaces" do
    options = tempfile_manifest(:type => "array-item", :key => "foo", :value => "bar")
    write_values(options[:filename], "foo", "' foo ' 'thing1 thing2 thing3' ' a b '")

    with_manifest(options[:manifest], "single array item") {
      # 'defaults' will literally-quote things when it feels like it.
      check_values(options[:filename], "foo", ["bar", '" foo "', '"thing1 thing2 thing3"', '" a b "'])
    }
  end

  context "with to-be-added elements containing spaces" do
    options = tempfile_manifest(:type => "array-item", :key => "foo", :value => " thing1 thing2 ")
    write_values(options[:filename], "foo", "' foo ' bar")

    with_manifest(options[:manifest], "single array item containing spaces") {
      # 'defaults' will literally-quote things when it feels like it.
      check_values(options[:filename], "foo", ['" thing1 thing2 "', '" foo "', "bar"])
    }
  end

  context "with a nonexistent .plist file" do
    options = tempfile_manifest(:type => "array-item", :key => "foo", :value => "bar")
    File.unlink(options[:filepath])

    with_manifest(options[:manifest], "single array item") do
      check_values(options[:filename], "foo", ["bar"])
      it "creates .plist file during run" do
        expect(file(options[:filepath])).to be_file
      end
    end
  end

  # in each write/positional mode:
  # => puts existing keys back
  # => preserves spaces/special chars in existing keys
  # => preserves spaces/special chars in added keys

end
