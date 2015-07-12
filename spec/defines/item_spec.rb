require "puppetlabs_spec_helper/module_spec_helper"
require "facets"

describe "plist::item", :type => "define" do
	let(:title) { "test" }

	describe "domain/key/plistfile XOR assertions" do
		let(:xorfailuremessage) { "'domain' and 'key' must both be set, and cannot be combined with 'plistfile'" }
		params = {
			:ensure => "foo",
			:domain => "foo",
			:key => "foo",
			:plistfile => "foo",
		}

		context "when only 'ensure' is supplied" do
			let(:params) { params.slice(:ensure) }
			it { is_expected.to raise_error(Puppet::Error, /#{xorfailuremessage}/ ) }
		end

		context "when 'domain' is supplied" do
			let(:params) { params.slice(:ensure, :domain) }
			it { is_expected.to raise_error(Puppet::Error, /#{xorfailuremessage}/) }
		end

		context "when 'domain', 'key', and 'plistfile' are supplied" do
			let(:params) { params }
			it { is_expected.to raise_error(Puppet::Error, /#{xorfailuremessage}/) }
		end

		context "when 'domain' and 'plistfile' are supplied" do
			let(:params) { params.except(:key) }
			it { is_expected.to raise_error(Puppet::Error, /#{xorfailuremessage}/) }
		end

		context "when 'domain' is supplied without 'key'" do
			let(:params) { params.except(:key, :plistfile) }
			it { is_expected.to raise_error(Puppet::Error, /#{xorfailuremessage}/) }
		end

		context "with 'host' and 'plistfile'" do
			let(:params) { params.except(:domain, :key).merge( :host => "foo" ) }
			it { is_expected.to raise_error(Puppet::Error, /'host' cannot be combined with 'plistfile'/) }
		end

		context "when 'plistfile' is supplied" do
			let(:params) { params.except(:domain, :key) }
			pending("Not implemented")
		end
	end

	describe "array-item delegation" do
		params = {
			:type => "array-item",
			:domain => "foo",
			:key => "bar",
		}

		context "with implicit value" do
			let(:params) { params }
			it { should contain_plist__array_item("TODO").with_ensure("present") }
			it { should contain_plist__array_item("TODO").with_value("test") }
		end

		context "with explicit value" do
			let(:params) { params.merge( :value => "foo" ) }
			it { should contain_plist__array_item("TODO").with_value("foo") }
		end

		context "with ensure => 'absent'" do
			let(:params) { params.merge( :ensure => "absent" ) }
			it { should contain_plist__array_item("TODO").only_with(
				:totally_nonexistent_param => nil, # Rspec-puppet bug; anything can be set here.
				:ensure => "absent",
				:value => "test",
				:write_command => "/usr/bin/defaults write foo bar -array",
				:read_command => "/usr/bin/defaults read foo bar -array",
				:append_command => "/usr/bin/defaults write foo bar -array-add",
			) }
		end

		context "with other customized parameters" do
			let(:params) { params.merge(
				:ensure => "present",
				:append => true,
			) }
			it { should contain_plist__array_item("TODO").only_with(
				:totally_nonexistent_param => nil, # Rspec-puppet bug; anything can be set here.
				:ensure => "present",
				:value => "test",
				:append => true,
				:write_command => "/usr/bin/defaults write foo bar -array",
				:read_command => "/usr/bin/defaults read foo bar -array",
				:append_command => "/usr/bin/defaults write foo bar -array-add",
			) }
		end

		context "with 'user'" do
			pending("Not implemented")
		end

		context "with 'host'" do
			pending("Not implemented")
		end
		# add user
		# add host
		# ensure passthroug of array-specific elts.

	end
end
