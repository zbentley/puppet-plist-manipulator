require "acceptance/spec_helper"
require "facets"

opts = {
  :type => "array-item",
  :key => "foo",
  :value => "bar",
}

context "with non-array item" do
  options = tempfile_manifest(opts.except(:type).merge( :ensure => "present" ))
  with_manifest(options[:manifest], "scalar item", :compile_failure => /TODO DODO/) do
    pending("not implemented")
  end
end

context "with existing elements containing spaces" do
  options = tempfile_manifest(opts)
  write_array_values(options[:filename], "foo", "' foo ' 'thing1 thing2 thing3' ' a b '")
  with_manifest(options[:manifest], "single array item") {
    # 'defaults' will literally-quote things when it feels like it.
    check_array_values(options[:filename], "foo", ["bar", '" foo "', '"thing1 thing2 thing3"', '" a b "'])
  }
end

context "with elements containing spaces" do
  options = tempfile_manifest(opts.merge(:value => " thing1 thing2 "))
  write_array_values(options[:filename], "foo", "' foo ' bar")
  with_manifest(options[:manifest], "single array item containing spaces") {
    # 'defaults' will literally-quote things when it feels like it.
    check_array_values(options[:filename], "foo", ['" thing1 thing2 "', '" foo "', "bar"])
  }
end

context "with a nonexistent .plist file" do
  options = tempfile_manifest(opts)
  File.unlink(options[:filepath])
  with_manifest(options[:manifest], "single array item") do
    check_array_values(options[:filename], "foo", ["bar"])
    it "creates .plist file during run" do
      expect(file(options[:filepath])).to be_file
    end
  end
end
