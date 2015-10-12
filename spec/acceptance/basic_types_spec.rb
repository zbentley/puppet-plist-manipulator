require "acceptance/spec_helper"
require "facets"

# for each type:
# create if nonexistent key
# create if nonexistent file
# modify (right type)
# try to modify (wrong type)

# for strings:
# multilines
# empties


context "creating string in nonexistent plist file" do
  opts = {
    :type => "string",
    :key => "foo",
    :value => "bar"
  }
  options = tempfile_manifest(opts)
  with_manifest(options[:manifest], "'string'-type item") do
    cmd = command("/usr/bin/defaults read-type #{options[:filepath]} #{opts[:key]}")
    it "creates a key with the right type" do
      expect(cmd.exit_status).to be_zero
      expect(cmd.stdout.strip()).to eq "Type is string"
    end
    check_scalar_value(options[:filename], opts[:key], opts[:value])
    it "creates .plist file during run" do
      expect(file(options[:filepath])).to be_file
    end
  end
end

context "writing empty string value" do
  opts = {
    :type => "string",
    :key => "foo",
    :value => ""
  }
  options = tempfile_manifest(opts)
  with_manifest(options[:manifest], "'string'-type item") do
    cmd = command("/usr/bin/defaults read-type #{options[:filepath]} #{opts[:key]}")
    it "creates a key with the right type" do
      expect(cmd.exit_status).to be_zero
      expect(cmd.stdout.strip()).to eq "Type is string"
    end
    check_scalar_value(options[:filename], opts[:key], opts[:value])
    it "creates .plist file during run" do
      expect(file(options[:filepath])).to be_file
    end
  end
end

context "writing multiline string value" do
  opts = {
    :type => "string",
    :key => "foo",
    :value => "\nfooo\nbar\n\n"
  }
  options = tempfile_manifest(opts)
  with_manifest(options[:manifest], "'string'-type item") do
    cmd = command("/usr/bin/defaults read-type #{options[:filepath]} #{opts[:key]}")
    it "creates a key with the right type" do
      expect(cmd.exit_status).to be_zero
      expect(cmd.stdout.strip()).to eq "Type is string"
    end
    check_scalar_value(options[:filename], opts[:key], opts[:value])
    it "creates .plist file during run" do
      expect(file(options[:filepath])).to be_file
    end
  end
end