require 'spec_helper'

describe 'Comment' do
  describe '::create' do
    let(:listing) { stub('listing', anchor_instance: stub('anchor-instance')) }
    let(:commenter) { stub('commenter', id: 123) }
    let(:text) { '1... 2... 3?' }
    let(:keywords) { stub('keywords') }
    let(:comment) { stub('comment') }

    it 'removes keywords from comment attrs and passes them to formatter' do
      CommentFormatter.any_instance.expects(:format).with(text, keywords, commenter).returns(text)
      listing.anchor_instance.expects(:comment).with(commenter.id, {text: text}).returns(comment)
      Comment.create(listing, commenter, text: text, keywords: keywords)
    end
  end

  context 'keyword parsing' do
    let(:text) do
      <<-HTML
some text with a hastag <span data-role='kw' data-kw-type='tag' data-kw-id='anime' data-kw-name='Anime'>#Anime</span>
and a mention <span data-role='kw' data-kw-type='cf' data-kw-id='1' data-kw-name='Ice Cube'>@Ice Cube</span> and stuff
      HTML
    end

    describe '#hashtags' do
      let(:anchor_stub) { stub('anchor comment', text: text) }
      let(:tags) { [stub('tag')] }
      subject { Comment.new(anchor_stub).hashtags }
      it 'only returns hashtags' do
        Tag.expects(:where).with(slug: ['anime']).returns(tags)
        expect(subject.count).to eq(1)
        expect(subject).to eq(tags)
      end
    end

    describe 'Comment::Parsed' do
      describe '#each' do
        subject { Comment::Parsed.new(text) }
        let(:nodes) { subject.to_a }

        it 'returns the right node count' do
          expect(subject.count).to eq(5)
        end

        it 'stores text as text' do
          [0,2,4].each { |i| expect(nodes[i]).to be_a(Comment::Parsed::Text) }
        end

        it 'stores hashtags as Hashtags' do
          expect(nodes[1]).to be_a(Comment::Parsed::Hashtag)
        end

        it 'stores hashtag attributes' do
          tag = nodes[1]
          expect(tag.id).to eq('anime')
          expect(tag.slug).to eq('anime')
          expect(tag.name).to eq('Anime')
        end

        it 'stores copious follows as CopiousFollows' do
          expect(nodes[3]).to be_a(Comment::Parsed::CopiousFollow)
        end
      end
    end
  end
end
