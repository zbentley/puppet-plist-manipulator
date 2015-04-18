require "serverspec"
require "rspec/expectations"
require "tempfile"
require "rake"

set :backend, :exec
set :disable_sudo, true

def with_manifest(name, manifest, &block)
  cxt = context "With #{name} manifest"

  cxt.class_eval do

    tempfile = Tempfile.new(["temp_manifest", ".pp"])
    tempfile.write(manifest)
    tempfile.flush

    after(:context) do
      tempfile.close
      tempfile.unlink
    end
    File.absolute_path(Rake.application.original_dir)
    # puppet apply --show_diff --verbose --detailed-exitcodes --noop --modulepath $modulepath $modulepath/site.pp
    # describe command("puppet apply --show_diff --verbose --detailed-exitcodes") do
    #   its(:exit_status) { should eq 0 }
    # end

    cxt.class_eval &block

    describe file("/etc/passwd"), "aft" do
      it { should be_file }

    end

     describe 'last' do
      it "should be fyle3" do
        expect(file(tempfile.path)).to be_file
      end
    end
  end

end


with_manifest "empty", "middle" do
  describe file("/etc/passwd") do
    it { should be_file }
  end
end


# def apply_manifest(manifest, opts = {}, &block)
#   puppet_apply_opts = {}
#   puppet_apply_opts[:verbose] = nil
#   puppet_apply_opts[:parseonly] = nil if opts[:parseonly]
#   puppet_apply_opts[:trace] = nil if opts[:trace]
#   puppet_apply_opts[:parser] = 'future' if opts[:future_parser]
#   puppet_apply_opts[:modulepath] = opts[:modulepath] if opts[:modulepath]
#   puppet_apply_opts[:noop] = nil if opts[:noop]
#   # From puppet help:
#   # "... an exit code of '2' means there were changes, an exit code of
#   # '4' means there were failures during the transaction, and an exit
#   # code of '6' means there were both changes and failures."
#   if [opts[:catch_changes],opts[:catch_failures],opts[:expect_failures],opts[:expect_changes]].compact.length > 1
#     raise(ArgumentError,
#           'Cannot specify more than one of `catch_failures`, ' +
#           '`catch_changes`, `expect_failures`, or `expect_changes` ' +
#           'for a single manifest')
#   end
#   if opts[:catch_changes]
#     puppet_apply_opts['detailed-exitcodes'] = nil
#   elsif opts[:catch_failures]
#     puppet_apply_opts['detailed-exitcodes'] = nil
#   elsif opts[:expect_failures]
#     puppet_apply_opts['detailed-exitcodes'] = nil
#   elsif opts[:expect_changes]
#     puppet_apply_opts['detailed-exitcodes'] = nil
#   end
#   # Not really thrilled with this implementation, might want to improve it
#   # later. Basically, there is a magic trick in the constructor of
#   # PuppetCommand which allows you to pass in a Hash for the last value in
#   # the *args Array; if you do so, it will be treated specially. So, here
#   # we check to see if our caller passed us a hash of environment variables
#   # that they want to set for the puppet command. If so, we set the final
#   # value of *args to a new hash with just one entry (the value of which
#   # is our environment variables hash)
#   if opts.has_key?(:environment)
#     puppet_apply_opts['ENV'] = opts[:environment]
#   end
#   manifest_tempfile = Tempfile.new(['plist_test_manifest', '.pp'])
#   begin
#     manifest_tempfile.write(manifest + "\n")
#     puppet('apply', manifest_tempfile.path, puppet_apply_opts)
#   ensure
#     manifest_tempfile.close
#     manifest_tempfile.unlink
#   end
# end

# expect(apply_manifest("", :catch_failures => true).exit_code).to be_zero
