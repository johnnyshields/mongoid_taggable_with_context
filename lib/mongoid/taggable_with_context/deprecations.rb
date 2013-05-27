module Mongoid::TaggableWithContext
  module Taggable::TaggableDeprecations
    # Validates the taggable options and raises errors if invalid options are detected.
    #
    # @param [ Hash ] options The taggable options.
    #
    # @since 2.0.0
    def self.validate(options)
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
      if options[:group_by_field]
        raise <<-ERR
          taggable :group_by_field option has been removed as of version 2.0.0. Please
          use taggregation :group_by option instead.
        ERR
      end
    end
  end

  module Taggregation::TaggregationDeprecations
    # Validates the taggregation options and raises errors if invalid options are detected.
    #
    # @param [ Hash ] options The taggregation options.
    #
    # @since 2.0.0
    def self.validate(options)
    end
  end

  module GroupBy
    module TaggableWithContext
      extend ActiveSupport::Concern
      included do
        raise <<-ERR
          Mongoid::TaggableWithContext::GroupBy::TaggableWithContext has been removed since
          version 1.1.1. Instead, please include both Mongoid::TaggableWithContext and
          Mongoid::TaggableWithContext::AggregationStrategy::RealTimeGroupBy
          in your Model.
        ERR
      end
    end
    module AggregationStrategy
      module RealTime
        extend ActiveSupport::Concern
        included do
          raise <<-ERR
            Mongoid::TaggableWithContext::GroupBy::AggregationStrategy::RealTime has been removed since
            version 1.1.1. Instead, please include both Mongoid::TaggableWithContext and
            Mongoid::TaggableWithContext::AggregationStrategy::RealTimeGroupBy
            in your Model.
          ERR
        end
      end
    end
  end
end