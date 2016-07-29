require "acceptance/spec_helper"
require "facets"

# for each type:
# create if nonexistent key
# create if nonexistent file
# modify (right type)
# try to modify (wrong type)
context "with nonexistent plist file" do

  test_manifest(
    :type => "string",
    :key => "foo",
    :value => "bar",
    :description => "new, nonempty string value"
  )

  test_manifest(
    :type => "string",
    :key => "foo",
    :value => "",
    :description => "empty string value"
  )

  test_manifest(
    :type => "string",
    :key => "foo",
    :value => "\nfooo\nbar\n\n",
    :description => "multiline string value"
  )

  pre_existing = tempfile_manifest(
    :type => "string",
    :key => "foo",
    :value => "bar"
  )
  with_manifest(pre_existing[:manifest], "pre-existing") do
    test_manifest(
      :type => "string",
      :key => "foo",
      :value => "baz",
      :description => "modifying existing value",
      :filepath => pre_existing[:filepath]
    )
  end
end

