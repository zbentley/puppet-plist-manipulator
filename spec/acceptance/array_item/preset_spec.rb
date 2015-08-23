require "acceptance/spec_helper"
require "facets"

def test_common_cases (opts)
  context "when prepending to an empty .plist file" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo")
    with_manifest(options[:manifest], "single array item") do
      check_array_values(options[:filename], "foo", ["bar"])
    end
  end

  context "when appending to an empty .plist file" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo")
    with_manifest(options[:manifest], "single array item") do
      check_array_values(options[:filename], "foo", ["bar"])
    end
  end

  context "when prepending a value to an array with one element" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "baz")
    with_manifest(options[:manifest], "single array item") {
      check_array_values(options[:filename], "foo", ["bar", "baz"])
    }
  end

  context "when appending a value to an array with one element" do
    options = tempfile_manifest(opts.merge( :value => "bar", :append => true ))
    write_array_values(options[:filename], "foo", "baz")
    with_manifest(options[:manifest], "single array item") {
      check_array_values(options[:filename], "foo", ["baz", "bar"])
    }
  end

  context "when instructed to prepend an already-existent value to an array with one element" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "bar")
    with_manifest(options[:manifest], "single array item", :expect_changes => false) {
      check_array_values(options[:filename], "foo", ["bar"])
    }
  end

  context "when instructed to prepend an already-existent value to an array with one element" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "bar")
    with_manifest(options[:manifest], "single array item", :expect_changes => false) {
      check_array_values(options[:filename], "foo", ["bar"])
    }
  end

  context "prepending a non-pre-existing value" do
    options = tempfile_manifest(opts.merge(:value => "four"))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items") {
      check_array_values(options[:filename], "foo", ["four", "one", "two", "three"])
    }
  end

  context "appending a non-pre-existing value" do
    options = tempfile_manifest(opts.merge(:value => "four", :append => true))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items") {
      check_array_values(options[:filename], "foo", ["one", "two", "three", "four"])
    }
  end

  context "when instructed to prepend a pre-existing value at the correct position" do
    options = tempfile_manifest(opts.merge(:value => "one"))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items", :expect_changes => false) {
      check_array_values(options[:filename], "foo", ["one", "two", "three"])
    }
  end

  context "when instructed to append a pre-existing value at the correct position" do
    options = tempfile_manifest(opts.merge(:value => "three", :append => true))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items", :expect_changes => false) {
      check_array_values(options[:filename], "foo", ["one", "two", "three"])
    }
  end
end


context "while in ensure => 'once' mode" do
  opts = {
    :type => "array-item",
    :ensure => "once",
    :key => "foo",
  }

  context "moving and prepending a pre-existing value" do
    options = tempfile_manifest(opts.merge(:value => "two"))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items") {
      check_array_values(options[:filename], "foo", ["two", "one", "three"])
    }
  end

  context "moving and appending a pre-existing value" do
    options = tempfile_manifest(opts.merge(:value => "two", :append => true))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items") {
      check_array_values(options[:filename], "foo", ["one", "three", "two"])
    }
  end
  test_common_cases(opts)
end

context "while in ensure => 'present' mode" do
  opts = {
    :type => "array-item",
    :ensure => "present",
    :key => "foo",
  }

  context "prepending a pre-existing value" do
    options = tempfile_manifest(opts.merge(:value => "two"))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items", :expect_changes => false) {
      check_array_values(options[:filename], "foo", ["one", "two", "three"])
    }
  end

  context "appending a pre-existing value" do
    options = tempfile_manifest(opts.merge(:value => "two", :append => true))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items", :expect_changes => false) {
      check_array_values(options[:filename], "foo", ["one", "two", "three"])
    }
  end
  test_common_cases(opts)
end

context "while in ensure => 'atposition' mode" do
  opts = {
    :type => "array-item",
    :ensure => "atposition",
    :key => "foo",
  }

  context "prepending a pre-existing value" do
    options = tempfile_manifest(opts.merge(:value => "two"))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items") {
      check_array_values(options[:filename], "foo", ["two", "one", "two", "three"])
    }
  end

  context "appending a pre-existing value" do
    options = tempfile_manifest(opts.merge(:value => "two", :append => true))
    write_array_values(options[:filename], "foo", "one two three")
    with_manifest(options[:manifest], "multiple word items") {
      check_array_values(options[:filename], "foo", ["one", "two", "three", "two"])
    }
  end
  test_common_cases(opts)
end
