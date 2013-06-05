module Mongoid::TaggableWithContext::Taggregation
  extend ActiveSupport::Concern

  class AggregationStrategyMissing < Exception; end
  class TagContextNotFound < Exception; end
  class InvalidStrategy < Exception; end # must be a subclass of Strategy (and not Strategy itself)
  class DuplicateTaggregationName < Exception; end

  included do
    class_attribute :has_global_taggregation_rule
    class_attribute :tag_aggregation_rules
    self.tag_aggregation_rules = HashWithIndifferentAccess.new
  end

  module ClassMethods
    # Macro to define a tag aggregation ("taggregation") rule for a
    # taggable field, including scope and grouping parameters. Multiple
    # aggregation rules may be defined simultaneously for the same field.
    #
    # @example Define an aggregation rule for a taggable field.
    #
    #   class Article
    #     include Mongoid::Document
    #     include Mongoid::TaggableWithContext
    #     field :category, type: String
    #     field :author, type: String
    #     taggable :keywords
    #     taggregation :keywords, name: :joes_keywords_by_category
    #                  group_by: :category, scope: ->{ where(author: 'Joe') }
    #   end
    #
    # @overload taggable(*contexts, options)
    #   Creates an aggregation rule and applies it to the user-specified tag contexts.
    #   @param [ Symbol ] contexts Optional list of tag context names to which to apply the rule. Applies to all
    #   tag contexts if not specified.
    #   @param [ Hash ] options Options for taggregation rule behavior.
    #
    # @overload taggable(options)
    #   Creates an aggregation rule for all tag contexts.
    #   @param [ Hash ] options Options for taggregation rule behavior.
    #
    # @option options [ String ] :name
    #   The method name to identify the aggregation. Supports tokens
    #   %{context} %{strategy} and %{group_by}. Will raise DuplicateTaggregationName
    #   error if two taggregation rules have the same name.
    # @option options [ Class ] :strategy
    #   The class of the aggregation strategy to use. Defaults to RealTime
    # @option options [ Symbol ] :group_by
    #   A field name whose value will be used to group the tag result set into buckets.
    #   Defaults to nil, i.e. do not group.
    # @option options [ Proc ] :scope
    #   A criteria selector by which filter the result set. Defaults to nil, i.e. the
    #   result is unscoped.
    #
    # @return [ Array<Rule> ] The newly created Taggregation::Rule objects.
    def taggregation(*args)
      options = args.extract_options!

      # Associate rule to all tag contexts if not explicit supplied
      if args.empty?
        args = tag_contexts.keys
        self.has_global_taggregation_rule = true
      end

      add_rules(args, options)
    end

    # @param [ Object ] group An optional group to restrict the
    #   result set, used only if the rule includes :group_by
    def tags_for(rule, group = nil)
      puts self.tag_aggregation_rules
      puts rule
      self.tag_aggregation_rules[rule].strategy.tags(group)
    end

    # @param [ Object ] group An optional group to restrict the
    #   result set, used only if the rule includes :group_by
    def tags_with_weight_for(rule, group = nil)
      puts self.tag_aggregation_rules
      puts rule
      self.tag_aggregation_rules[rule].strategy.tags_with_weight(group)
    end

    def aggregation_collection_for(rule)
      puts self.tag_aggregation_rules
      puts rule
      self.tag_aggregation_rules[rule].collection.name
    end

    def recalculate_tag_aggregations(context = nil)
      self.tag_aggregation_rules.each do |rule|
        rule.strategy.recalculate! if context.nil? || rule.context.name == context
      end
    end

    protected

    # Mass-creates a set of Taggregation::Rule objects for the given
    # contexts.
    #
    # @param [ Array<Symbol> ] contexts The context names to which to associate the rule.
    # @param [ Hash ] options The taggregation rule options.
    #
    # @options option [ Symbol ] see Taggregation::Rule#initialize
    #
    # @return [ Array<Rule> ] The newly created Taggregation::Rule objects.
    #
    # @since 2.0.0
    def add_rules(contexts, options)
      TaggregationDeprecations.validate(options)
      contexts.map do |context|
        add_rule(context, options)
      end
    end

    # Creates a single Taggregation::Rule object for the given
    # context, creates Model callbacks and methods, and
    # adds the rule to the list of taggregation rules.
    #
    # @param [ Array<Symbol> ] context The context names to which to associate the rule.
    # @param [ Hash ] options The taggregation rule options.
    #
    # @options option [ Symbol ] see Taggregation::Rule#initialize
    #
    # @return [ Array<Rule> ] The newly created Taggregation::Rule objects.
    #
    # @since 2.0.0
    def add_rule(context, options)
      rule = Rule.new(self, context, options.clone)
      insert_tag_aggregation_rule(rule)
      define_tag_aggregation_accessors(rule)
      define_tag_aggregation_strategy_callbacks(rule)
    end

    # Validates the taggregation rule does not have a duplicate
    # name, and if so inserts it into the tag_aggregation_rules hash
    #
    # @param [ Rule ] rule The taggregation rule to insert.
    #
    # @since 2.0.0
    def insert_tag_aggregation_rule(rule)
      if self.tag_aggregation_rules[rule.name]
        raise DuplicateTaggregationName
      else
        self.tag_aggregation_rules[rule.name] = rule
      end
    end

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
    #def add_tag_context(options)
    #  context = TagContext.new(options)
    #
    #  create_taggable_mongoid_field(context.db_field, options)
    #  create_taggable_mongoid_index(context.name)
    #  define_taggable_accessors(context.name)
    #
    #  self.tag_contexts[context.name] = context
    #  context
    #end

    # Defines all accessor methods for the taggable context at both
    # the instance and class level.
    #
    # @param [ Rule ] rule The taggregation rule.
    #
    # @since 2.0.0
    def define_tag_aggregation_accessors(rule)
      define_class_tags_getter(rule.name, rule.name)
      define_class_tags_with_weight_getter(rule.name, rule.name)
      define_class_aggregation_collection_getter(rule.name, rule.name)
      # define context names
      unless self.tag_aggregation_rules.keys.include? rule.context.name
        define_class_tags_getter(rule.name, rule.context.name)
        define_class_tags_with_weight_getter(rule.name, rule.context.name)
        define_class_aggregation_collection_getter(rule.name, rule.context.name)
      end
    end

    # Create the getter method to retrieve all tags
    # of a given rule on the Model class.
    #
    # @param [ String ] rule The name of the taggregation rule.
    #
    # @since 2.0.0
    def define_class_tags_getter(rule, meth)
      # retrieve all tags ever created for the model
      self.class.class_eval do
        define_method meth do |group = nil|
          tags_for(rule, group)
        end
      end
    end

    # Create the getter method to retrieve a weighted
    # array of tags of a given rule on the Model class.
    #
    # @param [ String ] rule The tag aggregation rule.
    #
    # @since 2.0.0
    def define_class_tags_with_weight_getter(rule, meth)
      self.class.class_eval do
        define_method :"#{meth}_with_weight" do |group = nil|
          tags_with_weight_for(rule, group)
        end
      end
    end

    # Create the getter method to retrieve a weighted
    # array of tags of a given rule on the Model class.
    #
    # @param [ String ] rule The tag aggregation rule.
    #
    # @since 2.0.0
    def define_class_aggregation_collection_getter(rule, meth)
      self.class.class_eval do
        define_method :"#{meth}_aggregation_collection" do
          aggregation_collection_for(rule)
        end
      end
    end


    # Create callbacks to the tag aggregation rule strategy.
    #
    # @param [ String ] rule The tag aggregation rule.
    #
    # @since 2.0.0
    def define_tag_aggregation_strategy_callbacks(rule)
      %w(create update upsert save destroy).each do |action|
        self.set_callback(action, :after) do |document|
          rule.strategy.send("after_#{action}",document)
        end if rule.strategy.respond_to? "after_#{action}"
      end
    end
  end
end
