require 'spec_helper'
require 'facets'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

describe 'plist::array_item', :type => 'define' do
	let(:title) { 'test' }

	describe 'domain/key/plistfile XOR assertions' do
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

		# ZBTODO implement
		context "when 'plistfile' is supplied" do
			let(:params) { params.except(:domain, :key) }
			it { is_expected.to raise_error(Puppet::Error, /not implemented/) }
		end

	end

	describe "'ensure' assertions" do
		params = {
			:ensure => "foo",
			:domain => "foo",
			:key => "foo",
		}

		context 'when no parameters are supplied' do
			let(:params) { {} }
			it { is_expected.to raise_error(Puppet::Error, /Must pass ensure/) }
		end

		context "when 'ensure' is invalid" do
			let(:params) { params }
			it { is_expected.to raise_error(Puppet::Error, /'ensure' must be 'once', 'present', or 'absent/) }
		end


		["present", "absent", "once"].each do |ens|
			context "when 'ensure' is '#{ens}'" do
				let(:params) { params.merge( :ensure => ens ) }
				it { should compile }
			end
		end

		context "'append' cannot be combined with 'ensure => absent'" do
			let(:params) { params.merge( :ensure => "absent", :append => true ) }
			it { is_expected.to raise_error(Puppet::Error, /'append' cannot be combined with ensure => 'absent'/) }
		end

		# ZBTODO implement
		["before_element", "after_element"].each do |notimp|
			context "'#{notimp}' not implemented" do
				let(:params) { params.merge( :ensure => "present", notimp => true ) }
				it { is_expected.to raise_error(Puppet::Error, /not implemented/) }
			end
		end
	end

    # it { should raise_error(Puppet::Error, /Either 'domain' and 'key' or 'plistfile' must be provided/) }
end
