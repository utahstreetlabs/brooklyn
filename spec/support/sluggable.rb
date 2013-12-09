# -*- encoding: utf-8 -*-

# Define a +new_record+ getter to use this. For example:
#
# describe Tag do
#   it_should_behave_like "a sluggable model" do
#     let(:new_record) { FactoryGirl.build(:tag) }
#   end
# end
shared_examples_for "a sluggable model" do |factory|
  let(:new_record) { FactoryGirl.build(factory) }

  it "sets a slug when saving the record" do
    new_record.save
    new_record.slug_field.should_not be_blank
  end

  it "cleans up non alphanumeric characters" do
    new_record.sluggable_field = "Jalapeños Are Great!"
    new_record.save
    new_record.slug_field.should == "jalapenos-are-great"
  end

  it "fails if the slug only has weird characters" do
    new_record.sluggable_field = "@#&!"
    new_record.should_not be_valid
    new_record.errors[new_record.class.slug_field].should have(1).elements
  end

  it "can reset and restore slugs" do
    new_record.sluggable_field = 'foo'
    new_record.slugify
    new_record.reset_slug
    new_record.slug_field.should == nil
    new_record.restore_slug
    new_record.slug_field.should == 'foo'
  end

  it "won't restore a slug if one has not been stored" do
    new_record.sluggable_field = 'foo'
    new_record.slugify
    new_record.restore_slug
    new_record.slug_field.should == 'foo'
  end

  context "disabling auto-generating the slug when validating" do
    before do
      new_record.extend Module.new {
        def should_slugify_before_validating?
          false
        end
      }
    end

    it "let's you fail for having blank slugs without regenerating it" do
      new_record.sluggable_field = "Some String"
      new_record.slug_field = nil

      new_record.should_not be_valid
      new_record.errors[new_record.class.slug_field].should_not be_empty
      new_record.slug_field.should be_blank
    end
  end
end

# Define a +new_record+ getter to use this. For example:
#
# describe User do
#   it_should_behave_like "a model with unique slugs" do
#     let(:new_record) { FactoryGirl.build(:user) }
#   end
# end
shared_examples_for "a model with unique slugs" do |factory|
  let(:new_record) { FactoryGirl.build(factory) }

  it_should_behave_like "a sluggable model", factory

  context "when the slug has already been used" do
    let! :other_record do
      new_record.dup
    end

    before do
      new_record.sluggable_field = "John"
      new_record.save
    end

    it "appends an autoincrementing number to the slug" do
      other_record.sluggable_field = new_record.sluggable_field
      other_record.save

      other_record.slug_field.should == "john-1"
    end

    it "appends the autoincrementing number, even if you try to force it" do
      other_record.slug_field = "john"
      other_record.save

      other_record.slug_field.should == "john-1"
    end

    it "doesn't try to change the slug if you're editing the record" do
      old_slug, new_record.slug_field = new_record.slug_field, nil
      new_record.save

      new_record.slug_field.should == old_slug
    end

    it "validates slug uniquess at the databse level" do
      second_record = FactoryGirl.build(factory)
      second_record.slug = new_record.slug
      second_record.save!(validate: false)

      second_record.slug_field.should == "john-1"
    end
  end
end
