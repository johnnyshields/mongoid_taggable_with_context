module Mongoid::TaggableWithContext::Taggable
  extend ActiveSupport::Concern

  class AggregationStrategyMissing < Exception; end
  # taggable cannot be called again after a global taggregation rule
  # (non-context specific) is set, since the global taggregation rule
  # has already initialized and will hence not include the newly
  # defined tag context.
  class TaggableAfterGlobalTaggregation < Exception; end
  class InvalidTagFormat < Exception; end

  included do
    class_attribute :tag_contexts
    self.tag_contexts = HashWithIndifferentAccess.new
  end

  # Returns tags in joined string format for a given context.
  #
  # @param [ Symbol ] context The name of the tag context.
  # @return [ String ] The joined tags string.
  #
  # @since 1.1.1
  def tag_string_for(context)
    self.read_attribute(context).join(tag_contexts[context].separator)
  end

  module ClassMethods

    # Macro to declare a document class as taggable, specify field name
    # for tags, and set options for tagging behavior.
    #
    # @example Define a taggable document.
    #
    #   class Article
    #     include Mongoid::Document
    #     include Mongoid::TaggableWithContext
    #     taggable :keywords, separator: ' ', default: ['foobar']
    #   end
    #
    # @param [ Symbol ] field The name of the field for tags. Defaults to :tags if not specified.
    # @param [ Hash ] options Options for taggable behavior.
    #
    # @option options [ String ] :separator
    #   The delimiter used when converting the tags to and from String format. Defaults to ' '
    # @option options [ Object ] :default, :as, :localize, etc.
    #   Options for Mongoid #field method will be automatically passed
    #   to the underlying Array field
    #
    # @return [ TagContext ] The newly added TagContext object.
    #
    # @since 1.0.0
    def taggable(*args)
      raise TaggableAfterGlobalTaggregation if has_global_taggregation_rule

      options = args.extract_options!
      options[:db_field] = args.shift.to_sym if args.present?
      added = add_tag_context(options)
      # TODO: test if this is needed
      # descendants.each do |subclass|
      #   subclass.add_taggable(field, options)
      # end
      added
    end

    # Find documents tagged with all tags passed as a parameter, given
    # as an Array or a String using the configured separator.
    #
    # @example Find matching all tags in an Array.
    #   Article.tagged_with(['ruby', 'mongodb'])
    # @example Find matching all tags in a String.
    #   Article.tagged_with('ruby, mongodb')
    #
    # @param [ String ] :field The field name of the tag.
    # @param [ Array<String, Symbol>, String ] :tags Tags to match.
    # @return [ Criteria ] A new criteria.
    #
    # @since 1.0.0
    def tagged_with(context, tags)
      all_in(tag_contexts[context].name => tag_contexts[context].format_tags(tags))
    end

    # Helper method to return the underlying Mongoid databaase
    # field names for all tag contexts in the Model.
    #
    # @return [ Array ] The array of database field names.
    #
    # @since 1.0.0
    def tag_database_fields
      self.tag_contexts.values.map(&:db_field)
    end
    
    protected

    # Creates a new TagContext from options, then creates the underlying
    # Mongoid field, Mongoid index, and alias methods for the context, and
    # finally adds it to the hash of tag contexts.
    #
    # @param [ Hash ] options The taggable options.
    #
    # @options option [ Symbol ] see TagContext#initialize
    #
    # @return [ TagContext ] The newly added TagContext object.
    #
    # @since 2.0.0
    def add_tag_context(options)
      context = TagContext.new(options.clone) # clone because options is reused for Mongoid

      create_taggable_mongoid_field(context.db_field, options)
      create_taggable_mongoid_index(context.name)

      define_taggable_accessors(context.name)

      self.tag_contexts[context.name] = context
      context
    end

    # Validates the taggable options and raises errors if invalid options are detected.
    #
    # @param [ Hash ] options The taggable options.
    #
    # @since 1.1.1
    def validate_taggable_options(options)
      if options[:field]
        raise <<-ERR
          taggable :field option has been removed as of version 1.1.1. Please use the
          syntax "taggable <database_name>, as: <tag_name>"
        ERR
      end
      if options[:string_method]
        raise <<-ERR
          taggable :string_method option has been removed as of version 1.1.1. Please
          define an alias to "<tags>_string" in your Model
        ERR
      end
    end

    # Creates the underlying Mongoid field for the tag context.
    #
    # @param [ Symbol ] name The name of the Mongoid field.
    # @param [ Hash ] options Options for the Mongoid field.
    #
    # @since 1.1.1
    def create_taggable_mongoid_field(name, options)
      field name, mongoid_field_options(options)
    end

    # Prepares valid Mongoid option keys from the taggable options. Slices
    # the taggable options to include only valid options for the Mongoid #field
    # method, and coerces :type to Array.
    #
    # @param [ Hash ] :options The taggable options hash.
    # @return [ Hash ] A options hash for the Mongoid #field method.
    #
    # @since 1.1.1
    def mongoid_field_options(options = {})
      options.slice(*::Mongoid::Fields::Validators::Macro::OPTIONS).merge!(type: Array)
    end

    # Creates an index for the underlying Mongoid field.
    #
    # @param [ Symbol ] name The name or alias name of Mongoid field.
    #
    # @since 1.1.1
    def create_taggable_mongoid_index(name)
      index({ name => 1 }, { background: true })
    end

    # Defines all accessor methods for the taggable context at both
    # the instance and class level.
    #
    # @param [ Symbol ] context The name of the tag context.
    #
    # @since 1.1.1
    def define_taggable_accessors(context)
      define_class_separator_getter(context)
      define_class_tagged_with_getter(context)
      define_instance_tag_string_getter(context)
      define_instance_tag_setter(context)
    end

    # Create the singleton getter method to retrieve the tag separator
    # for a given context for all instances of the model.
    #
    # @param [ Symbol ] context The name of the tag context.
    #
    # @since 1.1.1
    def define_class_separator_getter(context)
      self.class.class_eval do
        define_method :"#{context}_separator" do
          tag_contexts[context].separator
        end
      end
    end

    # Create the singleton getter method to retrieve the all
    # instances of the model which contain the tag/tags for a given context.
    #
    # @param [ Symbol ] context The name of the tag context.
    #
    # @since 1.1.1
    def define_class_tagged_with_getter(context)
      self.class.class_eval do
        define_method :"#{context}_tagged_with" do |tags|
          tagged_with(context, tags)
        end
      end
    end

    # Create the setter method for the provided taggable, using an
    # alias method chain to the underlying field method.
    #
    # @param [ Symbol ] context The name of the tag context.
    #
    # @since 1.1.1
    def define_instance_tag_setter(context)
      generated_methods.module_eval do
        re_define_method("#{context}_with_taggable=") do |value|
          value = self.class.tag_contexts[context].format_tags(value)
          self.send("#{context}_without_taggable=", value)
        end
        alias_method_chain "#{context}=", :taggable
      end
    end

    # Create the getter method for the joined tags string.
    #
    # @param [ Symbol ] context The name of the tag context.
    #
    # @since 1.1.1
    def define_instance_tag_string_getter(context)
      generated_methods.module_eval do
        re_define_method("#{context}_string") do
          self.tag_string_for(context)
        end
      end
    end
  end
end
