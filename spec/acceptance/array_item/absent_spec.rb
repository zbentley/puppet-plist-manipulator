require "acceptance/spec_helper"
require "facets"

context "while in ensure => 'absent' mode" do
  opts = {
    :type => "array-item",
    :ensure => "absent",
    :key => "foo",
  }

  # context ManifestTester.new(opts).with_array_values("foo"), "key: null in .plist file" do
  #   it_behaves_like "idempotently makes changes"
  # end

  # context ManifestTester.new(opts), "empty .plist file" do
  #   it_behaves_like "does not make changes"
  # end

  # context ManifestTester
  # .new(opts.merge( :value => "bar" ))
  # .with_array_values("foo", "baz"),
  # "single-element, non-matching array" do
  #   it_behaves_like "does not make changes"
  #   context "after application" do
  #     it "leaves correct data in the .plist file" do
  #       expect(subject.read_array_value("foo")).to eq(["baz"])
  #     end
  #   end

  # end

  # context ManifestTester
  # .new(opts.merge( :value => "bar" ))
  # .with_array_values("foo", "bar"),
  # "single-element, matching array" do
  #   it_behaves_like "idempotently makes changes"
  #   context "after application" do
  #     it "leaves correct data in the .plist file" do
  #       expect(subject.read_array_value("foo")).to eq([])
  #     end
  #   end
  # end

  context ManifestTester
  .new(opts.merge( :value => "bar" ))
  .with_array_values("foo", "bar bar bar"),
  "multiple-element, matching array" do
    it_behaves_like "idempotently makes changes"
    context "after application" do
      it "leaves correct data in the .plist file" do
        expect(subject.read_array_value("foo")).to eq([])
      end
    end
  end

  context ManifestTester
  .new(opts.merge( :value => "bar" ))
  .with_array_values("foo", "first second"),
  "multiple-element, non-matching array" do
    it_behaves_like "does not make changes"
    context "after application" do
      it "leaves correct data in the .plist file" do
        expect(subject.read_array_value("foo")).to eq(["first", "second"])
      end
    end
  end

  context ManifestTester
  .new(opts.merge( :value => "bar" ))
  .with_array_values("foo", "bar first second"),
  "varied array (single match)" do
    it_behaves_like "idempotently makes changes"
    context "after application" do
      it "leaves correct data in the .plist file" do
        expect(subject.read_array_value("foo")).to eq(["first", "second"])
      end
    end
  end

  context ManifestTester
  .new(opts.merge( :value => "bar" ))
  .with_array_values("foo", "first bar second bar"),
  "varied array (single match)" do
    it_behaves_like "idempotently makes changes"
    context "after application" do
      it "leaves correct data in the .plist file" do
        expect(subject.read_array_value("foo")).to eq(["first", "second"])
      end
    end
  end
end