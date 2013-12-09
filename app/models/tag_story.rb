class TagStory < Story
  attr_accessor :tag

  def complete?
    super && self.tag.present?
  end

  def tag
    @tag ||= Tag.find(self.tag_id)
  end

  class << self
    # a tag story that doens't require lookup against rising tide when we already have all the information
    def local_stub(tag, type, actor)

      t = RisingTide::Story.new()

      stub = self.new(t)
      stub.type = type
      stub.tag = tag
      stub.actor = actor
      stub
    end
  end
end
