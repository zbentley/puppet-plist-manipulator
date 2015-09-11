require "acceptance/spec_helper"
require "facets"

context "while in ensure => 'absent' mode" do
  opts = {
    :type => "array-item",
    :ensure => "absent",
    :key => "foo",
    :value => "bar",
  }

  context "with an empty .plist file" do
    options = tempfile_manifest(opts)
    write_array_values(options[:filename], "foo")
    with_manifest(options[:manifest], "empty array item", :expect_changes => false) do
      check_array_values(options[:filename], "foo", [])
    end
  end

  context "with a single-element, non-matching array" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "baz")
    with_manifest(options[:manifest], "single element array", :expect_changes => false) do
      check_array_values(options[:filename], "foo", ["baz"])
    end
  end

  context "with a single-element, matching array" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "bar")
    with_manifest(options[:manifest], "single element array") do
      check_array_values(options[:filename], "foo", [])
    end
  end

  context "with a multiple-element, matching array" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "bar bar bar")
    with_manifest(options[:manifest], "single element array") do
      check_array_values(options[:filename], "foo", [])
    end
  end

  context "with a multiple-element, non-matching array" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "first second")
    with_manifest(options[:manifest], "multiple element array", :expect_changes => false) do
      check_array_values(options[:filename], "foo", ["first", "second"])
    end
  end

  context "with a varied array (single match)" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "bar first second")
    with_manifest(options[:manifest], "multiple element array") do
      check_array_values(options[:filename], "foo", ["first", "second"])
    end
  end

  context "with a varied array (multiple matches)" do
    options = tempfile_manifest(opts.merge( :value => "bar" ))
    write_array_values(options[:filename], "foo", "first bar second bar")
    with_manifest(options[:manifest], "multiple element array") do
      check_array_values(options[:filename], "foo", ["first", "second"])
    end
  end
end