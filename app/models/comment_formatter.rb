require 'nokogiri'

class CommentFormatter
  def format(text, keyword_data, commenter)
    return text if keyword_data.blank?

    doc = Nokogiri::HTML::fragment('')
    keyword_data.each do |key, val|
      prefix = generate_keyword_prefix(val)
      regexp = /[\b|#{Regexp.escape(prefix)}]#{Regexp.escape(key)}\b/i

      # keyword_data can contain hashes for keywords that are not in the text
      if prefix.present? && text.match(regexp) && validate_keyword(val, commenter)
        # Treat as Copious follower if one exists, since we want to follow the Copious user flow when possible
        keyword_data[key] = val = facebook_to_copious_follower_keyword(val) if val['type'] == 'fb'
        text = text.gsub(regexp, generate_keyword_markup(val, prefix, doc))
      else
        keyword_data.delete(key)
      end
    end

    text
  end

  def facebook_to_copious_follower_keyword(keyword)
    profile = Profile.find_for_uid_and_network(keyword['id'], Network::Facebook.symbol)
    user = profile.user if profile
    return keyword unless profile && user
    {'id' => user.id, 'name' => keyword['name'], 'type' => 'cf'}
  end

  def generate_keyword_prefix(keyword)
    # prefix should be a single character that marks the start of a keyword in text
    if keyword['type'] == 'tag'
      '#'
    elsif keyword['type'] == 'cf' || keyword['type'] == 'fb'
      '@'
    else
      ''
    end
  end

  # HTML microformat markers
  def generate_keyword_markup(keyword, prefix, doc)
    return '' if keyword['name'].blank?

    tag = Nokogiri::XML::Node.new('span', doc)
    tag.content = prefix + keyword['name']
    tag['data-role'] = 'kw'
    tag["data-kw-slug"] = User.find(keyword['id']).slug if keyword['type'] == 'cf'

    keyword.each do |key, val|
      tag["data-kw-#{key}"] = val
    end

    tag.to_html
  end

  def validate_keyword(keyword, commenter)
    validator = KeywordValidator.create(keyword, commenter)
    return false unless validator
    validator.valid?
  end

  class KeywordValidator
    attr_reader :keyword, :commenter

    def initialize(keyword, commenter)
      @keyword = keyword
      @commenter = commenter
    end

    # Determines whether the keyword represents a valid entity. May mutate the keyword's state in the process.
    def valid?
      raise NotImplementedError
    end

    def self.create(keyword, commenter)
      case keyword['type']
      when 'tag' then HashTagValidator.new(keyword, commenter)
      when 'cf' then CopiousFollowerValidator.new(keyword, commenter)
      when 'fb' then FacebookUserValidator.new(keyword, commenter)
      else nil
      end
    end
  end

  class HashTagValidator < KeywordValidator
    # Determines whether the keyword represents a persisted tag. Creates the specified tag if necessary.
    def valid?
      begin
        return false if keyword['id'].blank? || keyword['name'].blank?
        new_tag = Tag.create!(name: keyword['name'])
        keyword['id'] = new_tag.slug
      rescue ActiveRecord::RecordInvalid
        # Exception raised if record already exists, which means hashtag is valid
      rescue
        return false
      end
      true
    end
  end

  class CopiousFollowerValidator < KeywordValidator
    # Determines whether the keyword represents a registered follower of the commenter.
    def valid?
      follower = User.find(keyword['id'])
      follower.registered? && follower.following?(commenter)
    rescue ActiveRecord::RecordNotFound
      false
    end
  end

  class FacebookUserValidator < KeywordValidator
    # Determines whether the keyword represents a FB user and the commenter is connected to FB.
    def valid?
      # Return true even if fb_user is not a friend of commenter because we want to mark-up the keyword
      commenter_profile = commenter.for_network(Network::Facebook.symbol)
      friend_profile = Profile.find_for_uid_and_network(keyword['id'], Network::Facebook.symbol)
      commenter_profile && friend_profile
    end
  end
end
