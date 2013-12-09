require 'spec_helper'

describe ApplicationController do
  describe "#absolute_url" do
    it "should absolutize relative urls" do
      subject.send(:absolute_url, '/foo/small_facebook.gif', root_url: 'http://test.host/').should ==
        "http://test.host//foo/small_facebook.gif"
    end

    it "should absolutize protocol relative urls" do
      subject.send(:absolute_url, '//images.memegenerator.net/images/195x/1721894.jpg').should ==
        'http://images.memegenerator.net/images/195x/1721894.jpg'
    end

    it "should leave absolute urls ALONE" do
      subject.send(:absolute_url, 'http://images.memegenerator.net/images/195x/1721894.jpg').should ==
        'http://images.memegenerator.net/images/195x/1721894.jpg'
    end
  end
end
