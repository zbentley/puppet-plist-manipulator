require "serverspec"
require "tempfile"
require "rake"

set :backend, :exec
set :disable_sudo, true

# Keep the tempfile variables in a global to prevent them from being destroyed
# when we don't want them to be.
$tempfiles = []
def tempfile_manifest(opts)
  tmpfile = Tempfile.new(['com.test', '.plist'], File.join(Dir.home, 'Library', 'Preferences'))
  $tempfiles.push(tmpfile)
  plist_file_name = File.basename(tmpfile.path)
  manifest_attrs = "";
  opts.each do |key, value|
    # Don't quote booleans.
    unless value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value = "'#{value}'"
    end
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

def write_array_values(filename, key, values = "")
  it "can set up file" do
    cmd = command("/usr/bin/defaults write #{filename} #{key} -array #{values}")
    expect(cmd.exit_status).to be_zero
    expect(cmd.stdout).to be_empty
  end
end

def check_array_values(filename, key, values = [])
  cmd = command("/usr/bin/defaults read #{filename} #{key}")
  it "key has expected values" do
    expect(cmd.exit_status).to be_zero
    # Discard the first and last (parentheses), trailing commas, and strip whitespace on the rest.
    significantvalues = cmd.stdout.split("\n").map! do |item|
      item.strip().chomp(",")
    end
    # Empty arrays include extra curlies in the output, for some reason.
    if significantvalues[0] == "{" && significantvalues[-1] == "}"
      significantvalues = significantvalues[1...-1]
    end
    # Also strip off the array start/end parentheses.
    expect(significantvalues[1...-1]).to eq values
  end
end

def check_scalar_value(filename, key, value)
  cmd = command("/usr/bin/defaults read #{filename} #{key}")
  it "key has expected value" do
    expect(cmd.exit_status).to be_zero
    # Remove a single trailing newline. The rest are useful for testing literal newlines.
    expect(cmd.stdout.chomp).to eq value
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
    cmd = "puppet apply --detailed-exitcodes --color false --modulepath #{puppetpath}/modules #{tempfile.path}"
    after(:context) do
      tempfile.close
      tempfile.unlink
    end

    result = command(cmd)
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