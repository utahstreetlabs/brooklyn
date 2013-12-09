# A model backed by a Ladon model rather than a database table. Understands how to resolve associations between the
# decorated model and Brooklyn models.
class LadonDecorator
  class RecordNotSaved < Exception; end

  attr_reader :decorated

  # Initializes a decorator based on a provided Ladon model. If the provided model is +nil+ then a new instance of
  # the decorated class is created.
  #
  # @param [<decorated class>] decorated a Ladon model
  # @return [LadonDecorator] 
  def initialize(decorated = nil)
    @decorated = decorated || self.class.decorated_class.new or
      raise RecordNotSaved
  end

  # Updates the decorated model based on the provided attributes. The underlying model's validations are checked, and
  # validation failures produce errors as normal. Requires that the model's id be set.
  #
  # @param [Hash] attrs a hash of attribute values to update the model with
  # @raise [Exception] if the model's id is not set
  # @return [Boolean] whether or not the update succeeded
  def update(attrs)
    raise Exception.new("model's id must be set") unless id.present?
    attrs = self.class.decorated_attributes(attrs)
    attrs[:_id] = id
    @decorated = @decorated.class.update(id, attrs)
    @decorated && @decorated.errors.empty?
  end

  # Returns whether or not this model is completely populated; ie, have all of its associations been resolved
  # successfully? Subclasses should override to check the state of associated models.
  def complete?
    true
  end

  # Returns the inverse of +#complete?+.
  def incomplete?
    not complete?
  end

  def method_missing(meth, *args, &block)
    @decorated.send(meth, *args, &block)
  end

  def respond_to?(meth)
    super || @decorated.respond_to?(meth)
  end

  def to_model
    self
  end

  class << self
    attr_reader :decorated_class

    # Sets the class which this class decorates.
    #
    # @param [Class] clazz the decorated class
    # @return [Class] the decorated class
    def decorates(clazz)
      raise ArgumentError.new("Decorated class must be an instance of Class") unless clazz.is_a?(Class)
      @decorated_class = clazz
    end

    def method_missing(meth, *args, &block)
      decorated_class.send(meth, *args, &block)
    end

    def respond_to?(meth)
      super || decorated_class.respond_to?(meth)
    end

    # Finds and returns all instances of the decorated class as decorated models.
    #
    # @param [Hash] options options controlling association resolution
    # @return [Array] the found models
    def all(options = {})
      objs = decorated_class.all.map { |o| new(o) }
      resolve_associations(objs, options)
    end

    # Finds the identified instance of the decorated class as a decorated model.
    #
    # @param [Integer] id the unique id of the instance to find
    # @param [Hash] options options controlling association resolution
    # @return [<decorated class>] the found model, or +nil+
    def find(id, options = {})
      decorated = decorated_class.find(id)
      decorated ? resolve_associations([new(decorated)], options).first : nil
    end

    # Creates an instance of the decorated class based on the provided attributes. The underlying model's validations
    # are checked, and validation failures produce errors as normal.
    #
    # @param [Hash] attrs a hash of attribute values to created the model with
    # @return [<decorated class>] the created model
    def create(attrs)
      new(decorated_class.create(decorated_attributes(attrs)))
    end

    # Returns the provided decorated models after resolving any associations with Brooklyn models. The details of
    # association resolution are to be provided by subclasses, including the meaning of any provided options.
    #
    # @param [Array] objs the decorated models whose associations are to be resolved
    # @param [Hash] options options controlling association resolution
    def resolve_associations(objs, options = {})
      objs
    end

    # Allows the subclass to augment attributes specified for the creation or update of a decorated model before
    # forwarding the operation on to the underlying model.
    #
    # @param [Hash] attrs the attributes to be applied to the underlying model
    def decorated_attributes(attrs = {})
      attrs.dup
    end
  end
end
