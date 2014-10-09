require "test_helper"

module MockAttributes
  def self.included(base)
    base.attribute :foo
    base.attribute :bar
    base.attribute :biz
    base.attribute :baz
    base.attribute :bang
    base.attribute :foz
    base.attribute :fuz
  end
end

class StripAllMockRecord < Tableless
  include MockAttributes
  strip_attributes :strip => :true
end

class StripOnlyOneMockRecord < Tableless
  include MockAttributes
  strip_attributes :only => :foo, :strip => :true
end

class StripOnlyThreeMockRecord < Tableless
  include MockAttributes
  strip_attributes :only => [:foo, :bar, :biz], :strip => :true
end

class StripExceptOneMockRecord < Tableless
  include MockAttributes
  strip_attributes :except => :foo, :strip => :true
end

class StripExceptThreeMockRecord < Tableless
  include MockAttributes
  strip_attributes :except => [:foo, :bar, :biz], :strip => :true
end

class StripAllowEmpty < Tableless
  include MockAttributes
  strip_attributes :allow_empty => true, :strip => :true
end

class CollapseDuplicateSpaces < Tableless
  include MockAttributes
  strip_attributes :collapse_spaces => true, :strip => :true
end

class CoexistWithOtherValidations < Tableless
  attribute :number, :type => Integer

  strip_attributes :strip => :true
  validates :number, {
    :numericality => { :only_integer => true,  :greater_than_or_equal_to => 1000 },
    :allow_blank => true
  }
end

class StripRegexMockRecord < Tableless
  include MockAttributes
  strip_attributes :regex => /[\^\%&\*]/, :strip => :true
end

class StripWithIfFalse < Tableless
  include MockAttributes
  strip_attributes :if => false
end

class StripWithIfTrue < Tableless
  include MockAttributes
  strip_attributes :strip => :true, :if => true
end

class StripWithIfMethodFalse < Tableless
  include MockAttributes
  strip_attributes :if => :strip?
  def strip?
    false
  end
end

class StripWithIfMethodTrue < Tableless
  include MockAttributes
  strip_attributes :strip => :true, :if => :strip?
  def strip?
    true
  end
end

class SkipStripAllMockRecord < Tableless
  include MockAttributes
  strip_attributes :strip => false
end

class DoStripAllMockRecord < Tableless
  include MockAttributes
  strip_attributes :strip => true
end

class StripAttributesTest < MiniTest::Unit::TestCase
  def setup
    @init_params = { :foo => "\tfoo", :bar => "bar \t ", :biz => "\tbiz ", :baz => "", :bang => " ", :foz => " foz  foz", :fuz => " foz  foz " }
  end
  def test_should_exist
    assert Object.const_defined?(:StripAttributes)
  end

  def test_should_strip_all_fields
    record = StripAllMockRecord.new(@init_params)
    record.valid?
    assert_equal "foo",      record.foo
    assert_equal "bar",      record.bar
    assert_equal "biz",      record.biz
    assert_equal "foz  foz", record.foz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_only_one_field
    record = StripOnlyOneMockRecord.new(@init_params)
    record.valid?
    assert_equal "foo",      record.foo
    assert_equal "bar \t ",  record.bar
    assert_equal "\tbiz ",   record.biz
    assert_equal " foz  foz", record.foz
    assert_equal "",         record.baz
    assert_equal " ",        record.bang
  end

  def test_should_strip_only_three_fields
    record = StripOnlyThreeMockRecord.new(@init_params)
    record.valid?
    assert_equal "foo",      record.foo
    assert_equal "bar",      record.bar
    assert_equal "biz",      record.biz
    assert_equal " foz  foz", record.foz
    assert_equal "",         record.baz
    assert_equal " ",        record.bang
  end

  def test_should_strip_all_except_one_field
    record = StripExceptOneMockRecord.new(@init_params)
    record.valid?
    assert_equal "\tfoo",    record.foo
    assert_equal "bar",      record.bar
    assert_equal "biz",      record.biz
    assert_equal "foz  foz", record.foz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_all_except_three_fields
    record = StripExceptThreeMockRecord.new(@init_params)
    record.valid?
    assert_equal "\tfoo",    record.foo
    assert_equal "bar \t ",  record.bar
    assert_equal "\tbiz ",   record.biz
    assert_equal "foz  foz", record.foz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_and_allow_empty
    record = StripAllowEmpty.new(@init_params)
    record.valid?
    assert_equal "foo",      record.foo
    assert_equal "bar",      record.bar
    assert_equal "biz",      record.biz
    assert_equal "foz  foz", record.foz
    assert_equal "",         record.baz
    assert_equal "",         record.bang
  end

  def test_should_collapse_duplicate_spaces
    record = CollapseDuplicateSpaces.new(@init_params)
    record.valid?
    assert_equal "foo",     record.foo
    assert_equal "bar",     record.bar
    assert_equal "biz",     record.biz
    assert_equal "foz foz", record.foz
    assert_equal nil,       record.baz
    assert_equal nil,       record.bang
  end

  def test_should_strip_and_allow_empty_always
    record = StripAllowEmpty.new(@init_params)
    record.valid?
    record.assign_attributes(@init_params)
    record.valid?
    assert_equal "foo",      record.foo
    assert_equal "bar",      record.bar
    assert_equal "biz",      record.biz
    assert_equal "foz  foz", record.foz
    assert_equal "",         record.baz
    assert_equal "",         record.bang
  end

  def test_should_coexist_with_other_validations
    record = CoexistWithOtherValidations.new
    record.number = 1000.1
    assert !record.valid?, "Expected record to be invalid"
    assert record.errors.include?(:number), "Expected record to have an error on :number"

    record = CoexistWithOtherValidations.new(:number => " 1000.2 ")
    assert !record.valid?, "Expected record to be invalid"
    assert record.errors.include?(:number), "Expected record to have an error on :number"

    # record = CoexistWithOtherValidations.new(:number => " 1000 ")
    # assert record.valid?, "Expected record to be valid, but got #{record.errors.full_messages}"
    # assert !record.errors.include?(:number), "Expected record to have no errors on :number"
  end

  def test_should_strip_regex
    record = StripRegexMockRecord.new
    record.assign_attributes(@init_params.merge(:foo => "^%&*abc  "))
    record.valid?
    assert_equal "abc",        record.foo
    assert_equal "bar",        record.bar
  end  

  def test_strip_unicode
    # This feature only works if multi-byte characters are supported by Ruby
    return if "\u0020" != " "
    # U200A - HAIR SPACE
    # U200B - ZERO WIDTH SPACE
    record = StripOnlyOneMockRecord.new({:foo => "\u200A\u200B foo\u200A\u200B "})
    record.valid?
    assert_equal "foo",      record.foo
  end

  def test_should_not_strip_if_false
    record = StripWithIfFalse.new(@init_params)
    record.valid?
    assert_equal "\tfoo",    record.foo
    assert_equal "bar \t ",  record.bar
    assert_equal "\tbiz ",   record.biz
    assert_equal " foz  foz", record.foz
    assert_equal "",         record.baz
    assert_equal " ",        record.bang
  end

  def test_should_strip_if_true
    record = StripWithIfTrue.new(@init_params)
    record.valid?
    assert_equal "foo",      record.foo
    assert_equal "bar",      record.bar
    assert_equal "biz",      record.biz
    assert_equal "foz  foz", record.foz
    assert_nil record.baz
    assert_nil record.bang
  end  

  def test_should_not_strip_if_method_false
    record = StripWithIfMethodFalse.new(@init_params)
    record.valid?
    assert_equal "\tfoo",    record.foo
    assert_equal "bar \t ",  record.bar
    assert_equal "\tbiz ",   record.biz
    assert_equal " foz  foz", record.foz
    assert_equal "",         record.baz
    assert_equal " ",        record.bang
  end

  def test_should_strip_if_method_true
    record = StripWithIfMethodTrue.new(@init_params)
    record.valid?
    assert_equal "foo",      record.foo
    assert_equal "bar",      record.bar
    assert_equal "biz",      record.biz
    assert_equal "foz  foz", record.foz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_not_strip_all_fields
    record = SkipStripAllMockRecord.new(@init_params)
    record.valid?
    assert_equal "\tfoo",      record.foo
    assert_equal "bar \t ",    record.bar
    assert_equal "\tbiz ",     record.biz
    assert_equal " foz  foz",  record.foz
    assert_equal " foz  foz ", record.fuz
    assert_equal " ",          record.bang
    assert_nil record.baz
  end

  def test_should_strip_all_fields
    record = DoStripAllMockRecord.new(@init_params)
    record.valid?
    assert_equal "foo",      record.foo
    assert_equal "bar",      record.bar
    assert_equal "biz",      record.biz
    assert_equal "foz  foz", record.foz
    assert_nil record.baz
    assert_nil record.bang
  end
end
