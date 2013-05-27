require 'active_support/concern'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'mongoid/taggable_with_context'
require 'mongoid/taggable_with_context/taggable'
require 'mongoid/taggable_with_context/taggable/tag_context'
require 'mongoid/taggable_with_context/taggregation'
require 'mongoid/taggable_with_context/aggregation_strategy/strategy'
require 'mongoid/taggable_with_context/aggregation_strategy/default_storage'
require 'mongoid/taggable_with_context/aggregation_strategy/map_reduce'
require 'mongoid/taggable_with_context/aggregation_strategy/real_time'
require 'mongoid/taggable_with_context/taggregation/rule'
require 'mongoid/taggable_with_context/deprecations'
require 'mongoid/taggable_with_context/version'