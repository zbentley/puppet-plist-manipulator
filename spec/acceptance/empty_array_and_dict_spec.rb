require "acceptance/spec_helper"
require "facets"

opts = {
  :type => "array",
  :key => "foo",
}

context "empty dictionary with pre-existing .plist file" do
  options = tempfile_manifest(opts.merge(:type => "dictionary"))
  with_manifest(options[:manifest], "'dict'-type item") do
    cmd = command("/usr/bin/defaults read-type #{options[:filepath]} #{opts[:key]}")
    it "creates a key with the right type" do
      expect(cmd.exit_status).to be_zero
      expect(cmd.stdout.strip()).to eq "Type is dictionary"
    end
    check_array_values(options[:filename], options[:key], [])
    it "creates .plist file during run" do
      expect(file(options[:filepath])).to be_file
    end
  end
end

context "empty array with a nonexistent .plist file" do
  options = tempfile_manifest(opts)
  File.unlink(options[:filepath])
  with_manifest(options[:manifest], "'array'-type item") do
    cmd = command("/usr/bin/defaults read-type #{options[:filepath]} #{opts[:key]}")
    it "creates a key with the right type" do
      expect(cmd.exit_status).to be_zero
      expect(cmd.stdout.strip()).to eq "Type is array"
    end
    check_array_values(options[:filename], options[:key], [])
    it "creates .plist file during run" do
      expect(file(options[:filepath])).to be_file
    end
  end
end

context "empty dictionary with a nonexistent .plist file" do
  options = tempfile_manifest(opts.merge(:type => "dict"))
  File.unlink(options[:filepath])
  with_manifest(options[:manifest], "'dict'-type item") do
    cmd = command("/usr/bin/defaults read-type #{options[:filepath]} #{opts[:key]}")
    it "creates a key with the right type" do
      expect(cmd.exit_status).to be_zero
      expect(cmd.stdout.strip()).to eq "Type is dictionary"
    end
    check_array_values(options[:filename], options[:key], [])
    it "creates .plist file during run" do
      expect(file(options[:filepath])).to be_file
    end
  end
end