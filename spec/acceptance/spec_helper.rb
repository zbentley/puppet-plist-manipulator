require "serverspec"
require "tempfile"
require "rake"
require 'json'
require 'rspec/its'

set :backend, :exec
set :disable_sudo, true

# Keep the tempfile variables in a global to prevent them from being destroyed
# when we don't want them to be.
$tempfiles = []

# Makes a new temporary file in ~/Library/Preferences, and writes a puppet
# manifest containing the supplied opts in a plist::item declaration to it.
# Opts are passed straight through to build_manifest.
def tempfile_manifest(opts)
  tmpfile = Tempfile.new(['com.test', '.plist'], File.join(Dir.home, 'Library', 'Preferences'))
  $tempfiles.push(tmpfile)
  plist_file_name = File.basename(tmpfile.path)
  return {
    :manifest => build_manifest(opts.merge(:domain => plist_file_name)),
    :filepath => tmpfile.path,
  }
end

# Gets a string manifest containing the supplied options hash in puppetlang.
# TODO: There is probably a puppet internal function I could call for this.
def build_manifest(opts)
  manifest_attrs = ""
  opts.each do |key, value|
    # Don't quote booleans.
    unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value = "'#{value}'"
    end
    manifest_attrs += "\t#{key}  =>  #{value},\n"
  end

    manifest = <<END
plist::item { 'test' :
#{manifest_attrs};
}
END
  return manifest
end

# Write an array to the specified plist file name using 'defaults'. Asserts that
# no unexpected output is observed. 
def write_array_values(filename, key, values = "")
  it "can set up file" do
    cmd = command(["/usr/bin/defaults", "write", filename, key, "-array", values])
    expect(cmd.stdout).to be_empty
    expect(cmd.stderr).to be_empty
    expect(cmd.exit_status).to be_zero
  end
end

def test_manifest(opts)
  # [:type, :key, :value, :description].each do |i|
  #   if ! opts.has_key?(i)
  #     raise("missing #{i}; required arguments must be specified")
  #   end
  # end
  type = opts[:type]
  key = opts[:key]
  value = opts[:value]
  description = opts.delete(:description)
  manifest = opts.delete(:manifest) || ""
  filepath = opts.delete(:filepath)
  testopts = {
    :expect_changes => opts.delete(:expect_changes),
    :compile_failure => opts.delete(:compile_failure),
    :apply_failure => opts.delete(:apply_failure),
  }

  if filepath.nil?
    temp_resources = tempfile_manifest(opts)
    filepath = temp_resources[:filepath]
    manifest = temp_resources[:manifest]
  else
    manifest = build_manifest(opts.merge(:domain => File.basename(filepath)))
  end

  with_manifest(manifest, description, testopts) do
    it ".plist file exists after run" do
      expect(file(filepath)).to be_file
    end
    filename = File.basename(filepath)
    if type == "array-item"
      type = "array"
    end
    
    it "key has the right type" do
      cmd = command(["/usr/bin/defaults", "read-type", filename, key])
      if opts[:ensure] == "absent"
        expect(cmd.stdout).to be_empty
        expect(cmd.stderr).to match /The domain\/default pair of .+? does not exist/
        expect(cmd.exit_status).to eq 1
      else
        expect(cmd.stderr).to be_empty
        expect(cmd.stdout.strip()).to eq "Type is #{type}"
        expect(cmd.exit_status).to be_zero
      end
    end
    
    it "key has expected value(s)" do
      cmd = command(["/usr/bin/defaults", "read", filename, key])
      if opts[:ensure] == "absent"
        expect(cmd.stdout).to be_empty
        expect(cmd.stderr).to match /The domain\/default pair of .+? does not exist/
        expect(cmd.exit_status).to eq 1
      else
        expect(cmd.exit_status).to be_zero
        if type == "array"
          # Discard the first and last (parentheses), trailing commas, and strip whitespace on the rest.
          significantvalues = cmd.stdout.split("\n").map! do |item|
            item.strip().chomp(",")
          end
          # Empty arrays include extra curlies in the output, for some reason.
          if significantvalues[0] == "{" && significantvalues[-1] == "}"
            significantvalues = significantvalues[1...-1]
          end
          # Also strip off the array start/end parentheses.
          expect(significantvalues[1...-1]).to eq value
        else
          # Remove a single trailing newline. The rest are useful for testing literal newlines.
          expect(cmd.stdout.chomp).to eq value
        end
      end
    end
  end
end

def with_manifest(manifest, name = false, opts = {}, &block)
  unless opts.has_key? :expect_changes
    opts[:expect_changes] = true
  end
  name ||= "'#{manifest}'"
  context "with #{name} manifest" do
    tempfile = Tempfile.new(["temp_manifest", ".pp"])
    tempfile.write(manifest)
    tempfile.flush
    # The harness creates a symlink to modules in the fixtures directory.
    puppetpath = File.join(Rake.application.original_dir, "spec", "fixtures")
    puppetpath = File.absolute_path(puppetpath)
    cmd = "bundle exec puppet apply --detailed-exitcodes --color false --modulepath #{puppetpath}/modules #{tempfile.path}"
    after(:context) do
      tempfile.close
      tempfile.unlink
    end

    result = command([
      "bundle",
      "exec",
      "puppet",
      "apply",
      "--detailed-exitcodes",
      "--color",
      "false",
      "--modulepath",
      "#{puppetpath}/modules",
      tempfile.path
    ])
    expected_failure = opts[:compile_failure] || opts[:apply_failure]
    nochange_exitcode = opts[:apply_failure] ? 4 : 0;

    # for exit code information, see: https://docs.puppetlabs.com/references/3.6.2/man/agent.html
    context "while applying manifest" do
      if opts[:compile_failure]
        it "fails to compile" do
          expect(result.exit_status).to eq 1
        end
      elsif opts[:expect_changes]
        if opts[:apply_failure]
          it "fails to make changes" do
            expect(result.exit_status).to eq 6
          end
        else
          it "successfully makes changes" do
            expect(result.exit_status).to eq 2
          end
        end
      else
        it "does not make changes" do
          expect(result.exit_status).to eq nochange_exitcode
        end
      end

      if opts[:apply_failure] || opts[:compile_failure]
        it "outputs expected errors" do
          expect(result.stderr).to match /^Error:.*#{expected_failure}/
        end
      else
        it "does not output errors" do
          expect(result.stderr).to be_empty
          expect(result.stdout).not_to match /^Error:/
        end
      end
      if opts[:compile_failure]
        it "keeps failing" do
          result = command(cmd)
          expect(result.exit_status).to eq 1
          expect(result.stderr).to match /^Error:.*#{expected_failure}/
        end
      else
        it "is idempotent" do
          expect(command(cmd).exit_status).to eq nochange_exitcode
        end
      end
    end

    context "after manifest application" do
      # http://stackoverflow.com/questions/26538952/create-rspec-context-inside-a-function
      class_exec(&block)
    end
  end
end

class ManifestTester
  attr_reader :manifest
  attr_reader :setupcmd
  def initialize(opts, plistfile=nil)
    @manifestfile = Tempfile.new(["temp_manifest", ".pp"])
    if plistfile.nil?
      plistfile = Tempfile.new(['com.test.', '.plist'], File.join(Dir.home, 'Library', 'Preferences'))
    end
    @plistfile = plistfile
    @manifest = build_manifest(opts.merge(:domain => File.basename(@plistfile.path)))

    @manifestfile.write(@manifest)
    @manifestfile.flush
    $tempfiles.push(@manifestfile)
    $tempfiles.push(@plistfile)
  end

  def plistpath
    @plistfile.path
  end

  def _run
    # The harness creates a symlink to modules in the fixtures directory.
    puppetpath = File.join(Rake.application.original_dir, "spec", "fixtures")
    puppetpath = File.absolute_path(puppetpath)
    result = Serverspec::Type::Command.new([
      "bundle",
      "exec",
      "puppet",
      "apply",
      "--detailed-exitcodes",
      "--color",
      "false",
      "--modulepath",
      "#{puppetpath}/modules",
      @manifestfile.path
    ])
  end

  def to_s
    "test manifest:"
  end

  def reset
    !! remove_instance_variable(:@lastresult)
  end

  # http://blog.jayfields.com/2007/07/ruby-lazily-initialized-attributes.html
  def exit_status
    unless instance_variable_defined? :@lastresult
      @lastresult = _run
    end
    @lastresult.exit_status
  end

  def stdout
    unless instance_variable_defined? :@lastresult
      @lastresult = _run
    end
    @lastresult.stdout
  end 

  def stderr
    unless instance_variable_defined? :@lastresult
      @lastresult = _run
    end
    @lastresult.stderr
  end

  def info
    info = JSON.pretty_generate( {
      :stderr => stderr,
      :stdout => stdout,
      :exit_status => exit_status
    })
    "Manifest:\n#{manifest}\nCommand result:\n#{info}"
  end

  def _check_cmd (cmd, no_stdout=false)
    cmd = Serverspec::Type::Command.new(cmd)
    # TODO figure out some way to synchronously run rspec matchers on the setup stuff.
    if ( cmd.exit_status > 0 || ! cmd.stderr.empty? || ( no_stdout && ! cmd.stdout.empty? ) )
      info = JSON.pretty_generate({
        :stderr => cmd.stderr,
        :stdout => cmd.stdout,
        :exit_status => cmd.exit_status,
      })
      raise "Failed running #{cmd}: #{info}"
    end
    cmd.stdout
  end

  def with_array_values(key, values = "")
    _check_cmd([
      "/usr/bin/defaults",
      "write",
      plistpath,
      key,
      "-array",
      values
    ], true);
    self
  end

  def read_array_value(key = [])
    stdout = _check_cmd([
      "/usr/bin/defaults",
      "read",
      plistpath,
      key,
    ].flatten)
    # Discard the first and last (parentheses), trailing commas, and strip whitespace on the rest.
    significantvalues = stdout.split("\n").map! do |item|
      item.strip().chomp(",")
    end
    # Empty arrays include extra curlies in the output, for some reason.
    if significantvalues[0] == "{" && significantvalues[-1] == "}"
      significantvalues = significantvalues[1...-1]
    end
    # Also strip off the array start/end parentheses.
    significantvalues[1...-1]
  end

  # def check_scalar_value(filename, key, value)
  #   cmd = command("/usr/bin/defaults read #{filename} #{key}")
  #   it "key has expected value" do
  #   expect(cmd.exit_status).to be_zero
  #   # Remove a single trailing newline. The rest are useful for testing literal newlines.
  #   expect(cmd.stdout.chomp).to eq value
  # end
end


shared_examples "successfully makes changes" do |suffix|
  its(:exit_status) { is_expected.to eq(2), subject.info }
  its(:stderr) { is_expected.to be_empty, subject.info }
  its(:stdout) { is_expected.not_to match(/^Error:/), subject.info }
end

shared_examples "does not make changes" do
  its(:exit_status) { is_expected.to eq(0), subject.info }
  its(:stderr) { is_expected.to be_empty, subject.info }
  its(:stdout) { is_expected.not_to match(/^Error:/), subject.info }
end

shared_examples "idempotently makes changes" do
  context "first (state-changing) run" do
    it_behaves_like "successfully makes changes", "first run"
  end
  its(:reset) { is_expected.to be_true }
  context "second (non-state-changing) run" do
    it_behaves_like "does not make changes"
  end
end

shared_examples "fails to apply" do |expected_failure|
  its(:exit_status) { is_expected.to eq(6), subject.info }
  its(:stderr) { is_expected.to to match(/^Error:.*#{expected_failure}/), subject.info }
  its(:stdout) { is_expected.not_to match(/^Error:/), subject.info } # TODO pointless?
end

shared_examples "fails to apply repeatedly" do |expected_failure|
  context "first run" do
    it_behaves_like "fails to apply", expected_failure
  end
  its(:reset) { is_expected.to be_true }
  context "second run" do
    it_behaves_like "fails to apply", expected_failure
  end
end

shared_examples "fails to compile" do |expected_failure|
  its(:exit_status) { is_expected.to eq(1), subject.info }
  its(:stderr) { is_expected.to match(/^Error:.*#{expected_failure}/), subject.info }
  its(:stdout) { is_expected.not_to match(/^Error:/), subject.info } # TODO pointless?
end


