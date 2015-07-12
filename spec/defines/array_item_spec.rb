require 'puppetlabs_spec_helper/module_spec_helper'
require 'facets'

describe 'plist::array_item', :type => 'define' do
	let(:title) { 'test' }

	describe "'ensure' assertions" do
		let(:xorfailuremessage) { "'domain' and 'key' must both be set, and cannot be combined with 'plistfile'" }
		params = {
			:ensure => "foo",
			:value => "foo",
			:write_command => "/usr/bin/defaults write foo bar -array",
			:read_command => "/usr/bin/defaults read foo bar -array",
			:append_command => "/usr/bin/defaults write foo bar -array-add",
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
end
