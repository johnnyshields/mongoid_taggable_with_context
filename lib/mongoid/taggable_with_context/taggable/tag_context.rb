module Mongoid::TaggableWithContext::Taggable
  class TagContext

    DEFAULT_FIELD = :tags
    DEFAULT_SEPARATOR = ' '

    # @attribute [Symbol] name The name used to identify the tag context.
    attr_reader :name
    # @attribute [Symbol] db_field The name of the Mongoid database field.
    attr_reader :db_field
    # @attribute [String] separator The delimiter used to join/split tag strings.
    attr_reader :separator

    # Create tag context and initialize its members variables.
    #
    # @param [ Hash ] options Options for the tag context.
    #
    # @option options [ String ] :db_field
    #   The underlying database field of the tag context.
    # @option options [ String ] :as
    #   The alias name for the tag context. Will be the same as db_field
    #   if not specified.
    # @option options [ String ] :separator
    #   The delimiter used when converting the tags to and from String format.
    #   Defaults to ' '
    #
    # @since 2.0.0
    def initialize(options={})
      TaggableDeprecations.validate(options)
      @db_field  = options.delete(:db_field).try(:to_sym) || DEFAULT_FIELD
      @name      = options.delete(:as).try(:to_sym) || db_field
      @separator = options.delete(:separator) || DEFAULT_SEPARATOR
    end

    # Converts a tag input value of unknown type to a formatted and
    # compacted/cleaned array. Stateful since String case depends on separator value.
    #
    # @param [ Object ] value Tag value of unknown type.
    # @return [ Array ] Tag value as a formatted Array.
    #
    # @since 2.0.0
    def format_tags(value)
      clean_array(format_to_array(value))
    end

    protected

    # Helper method to convert a tag input value of unknown type
    # to an unformatted array. Raises an error if cannot be formatted.
    #
    # @param [ Object ] value Tag value of unknown type.
    # @return [ Array ] Tag value as an unformatted Array.
    #
    # @since 2.0.0
    def format_to_array(value)
      case value
        when Array then  value
        when String then value.split(separator)
        else raise InvalidTagFormat
      end
    end

    # Compacts and cleans an array with the following logic:
    # 1) remove all nil values
    # 2) strip all leading/trailing whitespaces
    # 3) remove all blank strings
    # 4) remove duplicate
    #
    # @param [ Array ] ary The unformatted array.
    # @return [ Array ] The formatted array.
    #
    # @since 2.0.0
    def clean_array(ary)
      ary.compact.map(&:strip).reject(&:blank?).uniq
    end
  end
end