require 'spec_helper'

puts MyModel.new

module Mongoid::TaggableWithContext::Taggregation
  describe Rule do
    let(:model){ MyModel }
    let(:context){ :tags }
    let(:options){ {} }
    subject{ Rule.new(model, context, options) }

    #    attr_reader :context
    #    attr_reader :model
    #    attr_reader :group_by
    #    attr_reader :scope
    #    attr_reader :options

    #    # @since 2.0.0
    #    def initialize(context, model, options)
    #
    #      TaggregationDeprecations.validate(options)
    #
    #      @context             = model.tag_contexts[context] || raise(TagContextNotFound)
    #      @model               = model
    #      @strategy_klass      = options.delete(:strategy) || DEFAULT_STRATEGY
    #      raise InvalidStrategy unless @strategy_klass <= Mongoid::TaggableWithContext::AggregationStrategy::Strategy
    #
    #      @raw_name            = options.delete(:name)
    #      @group_by            = options.delete(:group_by)
    #      @scope               = options.delete(:scope)
    #      @collection          = options.delete(:collection)
    #      @raw_collection_name = options.delete(:collection_name)
    #      @database            = options.delete(:database)
    #      @options             = options
    #
    #      # clean up unused variables
    #      @raw_collection_name, @database = nil, nil if @collection
    #    end
    #


    describe '#initialize' do
      its(:model){ should eq(MyModel) }
      its(:context){ should eq(MyModel.tag_contexts[:tags]) }
      context 'with invalid tag context' do
        let(:context){ :foobar }
        it 'should raise TagContextNotFound error' do
          expect{ subject }.to raise_error TagContextNotFound
        end
      end
      context 'defaults' do
        its(:name){ should eq('tags') }
        its(:name){ should eq('tags') }
        its(:name){ should eq('tags') }
        its(:name){ should eq('tags') }
        its(:name){ should eq('tags') }
      end
    end

    describe '#strategy' do
      it 'should memoize the strategy' do
        s = subject.strategy
        subject.strategy.should == s
      end
      context 'default' do
        its(:strategy){ should be_a(Rule::DEFAULT_STRATEGY) }
      end
      context 'when :strategy is a subclass of Strategy' do
        let(:options){ {strategy: Mongoid::TaggableWithContext::AggregationStrategy::MapReduce} }
        its(:strategy){ should be_a(Mongoid::TaggableWithContext::AggregationStrategy::MapReduce) }
      end
      context 'when :strategy is the Strategy class itself' do
        let(:options){ {strategy: Mongoid::TaggableWithContext::AggregationStrategy::Strategy} }
        it 'should raise InvalidStrategy error' do
          expect{ subject }.to raise_error InvalidStrategy
        end
      end
      context 'when :strategy is not a subclass of Strategy' do
        let(:options){ {strategy: Array} }
        it 'should raise InvalidStrategy error' do
          expect{ subject }.to raise_error InvalidStrategy
        end
      end
    end

      #context 'with options' do
      #  subject{ TagContext.new(separator: ',', db_field: 'foo') }
      #  its(:separator){ should eq(',')}
      #  its(:db_field){ should eq(:foo)}
      #  its(:name){ should eq(:foo)}
      #  context 'with :as option' do
      #    subject{ TagContext.new(separator: ',', db_field: 'foo', as: 'bar') }
      #    its(:separator){ should eq(',')}
      #    its(:db_field){ should eq(:foo)}
      #    its(:name){ should eq(:bar)}
      #  end
      #end
  end
end

  #  describe '#format_tags' do
  #    context 'when value is Array' do
  #      let(:value){ ['foo,bar  ', ' baz ', 'baz ', '   ', ' bar', 'bar', 'baz,,,qux'] }
  #      it 'should remove whitespace, blanks, and duplicates' do
  #        subject.format_tags(value).should == ["foo,bar", "baz", "bar", "baz,,,qux"]
  #      end
  #    end
  #    context 'when value is String' do
  #      let(:value){ 'foo,bar baz,bar   baz  bar  ,  bar   baz,,,qux cat,dog' }
  #      it 'should split and compact the string' do
  #        subject.format_tags(value).should == ["foo,bar", "baz,bar", "baz", "bar", ",", "baz,,,qux", "cat,dog"]
  #      end
  #      context 'when separator is explicitly set' do
  #        subject{ TagContext.new(separator: ',') }
  #        it 'should split and compact the string' do
  #          subject.format_tags(value).should == ["foo", "bar baz", "bar   baz  bar", "bar   baz", "qux cat", "dog"]
  #        end
  #      end
  #    end
  #    context 'when value is not Array or String' do
  #      let(:value){ {this: 'is', not: 'an', array: 'or string'} }
  #      it 'should raise an error' do
  #        expect{ subject.format_tags(value) }.to raise_error InvalidTagFormat
  #      end
  #    end
  #  end
  #end
#end
#
#
#
#module Mongoid::TaggableWithContext::Taggregation
#  class Rule
#
#    DEFAULT_STRATEGY = Mongoid::TaggableWithContext::AggregationStrategy::RealTime
#

#
#    # Create tag context and initialize its members variables.
#    #
#    # @param [ Symbol ] context The tag context target for the rule.
#    # @param [ Class ] model The klass of the model for this rule.
#    # @param [ Hash ] options Options for the tag context.
#    #
#    # @option options [ String ] :context
#    #   The name of the target context for the rule.
#    # @option options [ String ] :name
#    #   The raw name string for the rule, which may include the tokens
#    #   %{context}, %{strategy}, and %{group_by}.
#    # @option options [ Class ] :strategy
#    #   The class of the aggregation strategy to use. Defaults to RealTime
#    # @option options [ Symbol ] :group_by
#    #   A field name whose value will be used to group the tag result set into buckets.
#    #   Defaults to nil, i.e. do not group.
#    # @option options [ Proc ] :scope
#    #   A criteria selector by which filter the result set. Defaults to nil, i.e. the
#    #   result is unscoped.
#    # @option options [ Moped::Collection ] :collection
#    #   The database collection to store data associated with this rule
#    #   If not specified, :collection_name will used.
#    # @option options [ String ] :collection_name
#    #   If :collection is not specified, this will be the collection name to store data
#    #   associated with this rule. If not specified, a new collection name will be
#    #   generated.
#    # @option options [ Moped::Database ] :database
#    #   If :collection is not specified, this will be the database to store data
#    #   associated with this rule. If not specified, the database of the Model
#    #   will be used.
#    # @option options [ Object ] etc.
#    #   Any other options will be stored
#    #

#    # The formatted name for the rule, which will be used
#    # as a method name to access the rule on the Model class.
#    #
#    # @return The formatted rule name
#    #
#    # @since 2.0.0
#    def name
#      @name ||= detokenize(@raw_name || default_raw_name)
#    end
#
#    # The associated database collection with with this rule.
#    #
#    # @return The database collection for the rule
#    #
#    # @since 2.0.0
#    def collection
#      @collection ||= Moped::Collection.new(database, collection_name)
#    end
#
#    # Returns a memoized strategy instance for this rule.
#    #
#    # @return The memoized strategy instance
#    #
#    # @since 2.0.0
#    def strategy
#      @strategy ||= @strategy_klass.new(self)
#    end
#
#    protected
#
#    # Evaluates tokens for a rule name string.
#    #
#    # @param [ String ] str The unformatted rule name
#    # @return The formatted rule name
#    #
#    # @since 2.0.0
#    def detokenize(str)
#      subs = { context: context.name,
#               group_by: group_by || '',
#               strategy: @strategy_klass.name.demodulize.underscore || ''}
#
#      subs.inject(str) do |output, (token, sub)|
#        output.gsub("%{#{token}}", sub.to_s)
#      end
#    end
#
#    # Generates a default name for the rule in token format.
#    #
#    # @return The unformatted default rule name
#    #
#    # @since 2.0.0
#    def default_raw_name
#      str = '%{context}'
#      str += '_by_%{group_by}' if group_by
#      str += '_with_scope' if scope
#      str += '_via_%{strategy}' if @strategy_klass != DEFAULT_STRATEGY
#      str
#    end
#
#    def collection_name
#      @collection.try(:name) ||
#          detokenize(@raw_collection_name || default_raw_collection_name)
#    end
#
#    # Generates a default collection name for this rule.
#    #
#    # @return The default collection name for the rule
#    #
#    # @since 2.0.0
#    def default_raw_collection_name
#      "#{model.collection.name}_#{name}_aggregation"
#    end
#
#    # The associated database with with this rule.
#    #
#    # @return The database for the rule
#    #
#    # @since 2.0.0
#    def database
#      @collection.try(:database) || @database || model.collection.database
#    end
#  end
#end