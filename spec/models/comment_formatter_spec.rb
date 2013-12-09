require 'spec_helper'

describe CommentFormatter do
  describe "#generate_keyword_markup" do
    let(:doc) { Nokogiri::HTML::fragment('') }

    context "empty keyword" do
      let(:keyword) { {} }
      it "returns an empty string" do
        expect(subject.generate_keyword_markup(keyword, '', doc)).to eql('')
      end
    end

    context "keyword with name attribute" do
      let(:keyword) { {'name' => 'John'} }
      it "returns a keyword marker with name attribute" do
        expect(subject.generate_keyword_markup(keyword, '', doc)).to eql(
          "<span data-role=\"kw\" data-kw-name=\"John\">John</span>")
      end
    end

    context "keyword with prefix" do
      let(:keyword) { {'name' => 'John'} }
      it "returns a keyword marker prefix in content" do
        expect(subject.generate_keyword_markup(keyword, '@', doc)).to eql(
          "<span data-role=\"kw\" data-kw-name=\"John\">@John</span>")
      end
    end

    context "keyword with multiple attributes" do
      let(:keyword) { {'id' => '12345', 'name' => 'John_Doe', 'type' => 'cf'} }
      it "returns a keyword marker with multiple attributes" do
        User.stubs(:find).returns(stub_user('John Doe'))
        User.any_instance.stubs(:slug).returns('john-doe')
        expect(subject.generate_keyword_markup(keyword, '@', doc)).to eql(
          "<span data-role=\"kw\" data-kw-slug=\"john-doe\" data-kw-id=\"12345\" "\
          "data-kw-name=\"John_Doe\" data-kw-type=\"cf\">@John_Doe</span>")
      end
    end
  end

  describe "#validate_keyword" do
    let(:commenter) { stub_user('Mickey Rourke') }
    let(:mentioned) { stub_user('John Doe') }

    context "tag exists" do
      let(:keyword) { {'id' => 'black', 'name' => '#black', 'type' => 'tag'} }
      before { FactoryGirl.create(:tag, name: 'black') }
      it "returns true" do
        expect(subject.validate_keyword(keyword, commenter)).to be_true
      end
    end

    context "tag does not exist" do
      let(:keyword) { {'id' => 'asdf', 'name' => '#asdf', 'type' => 'tag'} }
      it "returns true" do
        expect(subject.validate_keyword(keyword, commenter)).to be_true
        expect(Tag.exists?(slug: 'asdf')).to be_true
      end
    end

    context "tag does not have id" do
      let(:keyword) { {'name' => '#black', 'type' => 'tag'} }
      it "returns false" do
        expect(subject.validate_keyword(keyword, commenter)).to be_false
      end
    end

    context "tag does not have name" do
      let(:keyword) { {'id' => 'black', 'type' => 'tag'} }
      it "returns false" do
        expect(subject.validate_keyword(keyword, commenter)).to be_false
      end
    end

    context "tag does not have type" do
      let(:keyword) { {'id' => 'black', 'name' => '#black'} }
      it "returns false" do
        expect(subject.validate_keyword(keyword, commenter)).to be_false
      end
    end

    context "mentioned copious user exists" do
      let(:commenter) { FactoryGirl.create(:registered_user) }
      let(:keyword) { {'id' => follower.id, 'name' => "##{follower.name}", 'type' => 'cf'} }

      context "and is registered" do
        let(:follower) { FactoryGirl.create(:registered_user) }
        it "returns true if mentioned copious user follows commenter" do
          FactoryGirl.create(:follow, user: commenter, follower: follower)
          expect(subject.validate_keyword(keyword, commenter)).to be_true
        end
        it "returns false if mentioned copious user does not follow commenter" do
          expect(subject.validate_keyword(keyword, commenter)).to be_false
        end
      end

      context "but is not registered" do
        let(:follower) { FactoryGirl.create(:inactive_user) }
        it "returns false if mentioned copious user follows commenter" do
          FactoryGirl.create(:follow, user: commenter, follower: follower)
          expect(subject.validate_keyword(keyword, commenter)).to be_false
        end
        it "returns false if mentioned copious user does not follow commenter" do
          expect(subject.validate_keyword(keyword, commenter)).to be_false
        end
      end
    end

    context "mentioned copious user does not exist" do
      let(:commenter) { FactoryGirl.create(:registered_user) }
      let(:keyword) { {'id' => 1234567890, 'name' => '#John_Doe', 'type' => 'cf'} }
      it "returns false" do
        expect(subject.validate_keyword(keyword, commenter)).to be_false
      end
    end

    context "commenter mentions a facebook user" do
      let(:keyword) { {'id' => mentioned.id, 'name' => '#John_Doe', 'type' => 'fb'} }
      it "returns true if commenter and mentioned user have facebook profiles" do
        commenter.stubs(:for_network).returns(true)
        Profile.stubs(:find_for_uid_and_network).returns(true)
        expect(subject.validate_keyword(keyword, commenter)).to be_true
      end
      it "returns false if commenter does not have facebook profile" do
        commenter.stubs(:for_network).returns(false)
        Profile.stubs(:find_for_uid_and_network).returns(true)
        expect(subject.validate_keyword(keyword, commenter)).to be_false
      end
      it "returns false if mentioned facebook user does not exist" do
        commenter.stubs(:for_network).returns(true)
        Profile.stubs(:find_for_uid_and_network).returns(false)
        expect(subject.validate_keyword(keyword, commenter)).to be_false
      end
    end
  end

  describe "#format" do
    let(:commenter) { stub_user('Mickey Rourke') }
    let(:text) { 'hello world #greeting #hello_greeting @John @John_Doe' }
    let(:doc) { Nokogiri::HTML::fragment('') }
    let(:follower) { stub_user('John Doe') }
    let(:follower_profile) { stub_network_profile('john-doe', :facebook) }
    before { subject.stubs(:validate_keyword).returns(true) }

    context "no keywords" do
      let(:keywords) { {} }
      it "returns text as is" do
        expect(subject.format(text, keywords, commenter)).to eql(text)
      end
    end

    context "no matching keywords" do
      let(:keywords) { {
        'asdf' => {'id' => 'asdf', 'name' => 'asdf', 'type' => 'tag'},
        'hello' => {'id' => 'hello', 'name' => 'hello', 'type' => 'tag'},
        'John_Doe' => {'id' => 'John-Doe', 'name' => 'John_Doe', 'type' => 'tag'},
        'greeting' => {'id' => '12345', 'name' => 'greeting', 'type' => 'cf'},
        'Jane_Doe' => {'id' => '123456789', 'name' => 'Jane_Doe', 'type' => 'fb'}
      } }
      it "returns text as is" do
        expect(subject.format(text, keywords, commenter)).to eql(text)
      end
    end

    context "keyword without type" do
      let(:keyword) { {'id' => 'greeting', 'name' => 'greeting'} }
      let(:keywords) { {'greeting' => keyword} }
      it "returns text as is" do
        expect(subject.format(text, keywords, commenter)).to eql(
          "hello world #greeting #hello_greeting @John @John_Doe")
      end
    end

    context "one hashtag" do
      let(:keyword) { {'id' => 'greeting', 'name' => 'greeting', 'type' => 'tag'} }
      let(:keywords) { {'greeting' => keyword} }
      it "returns text with one keyword marker" do
        expect(subject.format(text, keywords, commenter)).to eql(
          "hello world #{subject.generate_keyword_markup(keyword, '#', doc)} #hello_greeting @John @John_Doe")
      end
    end

    context "multiple hashtags" do
      let(:keywords) { {
        'greeting' => {'id' => 'greeting', 'name' => 'greeting', 'type' => 'tag'},
        'hello_greeting' => {'id' => 'hello-greeting', 'name' => 'hello greeting', 'type' => 'tag'}
      } }
      it "returns text with multiple keyword markers" do
        expect(subject.format(text, keywords, commenter)).to eql(
          "hello world #{subject.generate_keyword_markup(keywords['greeting'], '#', doc)} "\
          "#{subject.generate_keyword_markup(keywords['hello_greeting'], '#', doc)} @John @John_Doe")
      end
    end

    context "one facebook mention" do
      let(:keyword) { {'id' => '123456789', 'name' => 'John_Doe', 'type' => 'fb'} }
      let(:cf_keyword) { {'id' => '12345', 'name' => 'John_Doe', 'type' => 'cf'} }
      let(:keywords) { {'John_Doe' => keyword} }

      context "and is a copious user" do
        it "returns text with one copious follower keyword marker" do
          User.stubs(:find).returns(follower)
          User.any_instance.stubs(:slug).returns('john-doe')
          follower.stubs(:id).returns('12345')
          Profile.stubs(:find_for_uid_and_network).returns(follower_profile)
          follower_profile.stubs(:user).returns(follower)
          expect(subject.format(text, keywords, commenter)).to eql(
            "hello world #greeting #hello_greeting @John #{subject.generate_keyword_markup(cf_keyword, '@', doc)}")
        end
      end

      context "and is not a copious user" do
        it "returns text with one facebook keyword marker" do
          Profile.stubs(:find_for_uid_and_network).returns(follower_profile)
          follower_profile.stubs(:user).returns(nil)
          expect(subject.format(text, keywords, commenter)).to eql(
            "hello world #greeting #hello_greeting @John #{subject.generate_keyword_markup(keyword, '@', doc)}")
        end
      end
    end

    context "one facebook and copious follower mention" do
      let(:keywords) { {
        'John' => {'id' => '12345', 'name' => 'John', 'type' => 'cf'},
        'John_Doe' => {'id' => '123456789', 'name' => 'John_Doe', 'type' => 'fb'}
      } }
      it "returns text with multiple mention markers" do
        User.stubs(:find).returns(stub_user('John'))
        User.any_instance.stubs(:slug).returns('john')
        Profile.stubs(:find_for_uid_and_network).returns(follower_profile)
        follower_profile.stubs(:user).returns(nil)
        expect(subject.format(text, keywords, commenter)).to eql(
          "hello world #greeting #hello_greeting #{subject.generate_keyword_markup(keywords['John'], '@', doc)} "\
          "#{subject.generate_keyword_markup(keywords['John_Doe'], '@', doc)}")
      end
    end
  end
end
