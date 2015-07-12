require "serverspec"
require "tempfile"
require "rake"

set :backend, :exec
set :disable_sudo, true

def with_manifest(manifest, name = false, opts = {}, &block)
  unless opts.has_key? :expect_changes
    opts[:expect_changes] = true
  end
  name ||= "'#{manifest}'"
  context "with #{name} manifest" do
    tempfile = Tempfile.new(["temp_manifest", ".pp"])
    tempfile.write(manifest)
    tempfile.flush
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
        it "makes changes" do
          if opts[:apply_failure]
            expect(result.exit_status).to eq 6
          else
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
          expect(result.stdout).to match /^Error:.*#{expected_failure}/
        end
      else
        it "does not output errors" do
          expect(result.stdout).not_to match /^Error:.+/
        end
      end
      if opts[:compile_failure]
        it "keeps failing" do
          expect(command(cmd).exit_status).to eq 1
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
