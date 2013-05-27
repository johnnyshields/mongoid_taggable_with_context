module Mongoid::TaggableWithContext
  extend ActiveSupport::Concern

  class AggregationStrategyMissing < Exception; end

  included do
    include Mongoid::TaggableWithContext::Taggable
    include Mongoid::TaggableWithContext::Taggregation
  end
end
