class MyModel
  include Mongoid::Document
  include Mongoid::TaggableWithContext

  taggable
  taggable :artists, separator: ', '
  taggable :albums, default: []
end

class M1
  include Mongoid::Document
  include Mongoid::TaggableWithContext

  taggable
  taggable :a, as: :artists

  taggregation strategy: Mongoid::TaggableWithContext::AggregationStrategy::MapReduce
end

class M2
  include Mongoid::Document
  include Mongoid::TaggableWithContext

  taggable
  taggable :artists

  taggregation :artists, strategy: Mongoid::TaggableWithContext::AggregationStrategy::RealTime
end

class M3
  include Mongoid::Document
  include Mongoid::TaggableWithContext

  field :user

  taggable
  taggable :artists

  taggregation :tags, group_by: :user, strategy: Mongoid::TaggableWithContext::AggregationStrategy::RealTime
  taggregation :artists, group_by: :user, strategy: Mongoid::TaggableWithContext::AggregationStrategy::RealTime
end