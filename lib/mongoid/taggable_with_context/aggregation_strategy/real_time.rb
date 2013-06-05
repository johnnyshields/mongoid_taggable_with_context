module Mongoid::TaggableWithContext::AggregationStrategy
  class RealTime < Strategy
    include DefaultStorage

    def initialize(rule)
      super(rule)
      raise NotImplementedError.new(':scope is not yet implemented for MapReduce') if rule.scope
    end

    def after_save(document)
      update_tag_aggregation(document, *context_changes(document)) if context_changed?(document)
    end

    def after_destroy(document)
      update_tag_aggregation(document, context_value(document), [])
    end

    def recalculate!
      MapReduce.new(rule).recalculate!
    end

    # adapted from https://github.com/jesuisbonbon/mongoid_taggable/commit/42feddd24dedd66b2b6776f9694d1b5b8bf6903d
    def tags_autocomplete(context, criteria, options={})
      result = rule.collection.find({tag_name_attribute.to_sym => /^#{criteria}/})
      result = result.sort(value: -1) if options[:sort_by_count]
      result = result.limit(options[:max]) if options[:max] > 0
      result.to_a.map{ |r| [r[tag_name_attribute], r['value']] }
    end

    protected

    def tag_name_attribute
      '_id' # TODO: WHY???? "_name"
    end

    def update_tag_aggregation(document, old_tags=[], new_tags=[])
      coll = rule.collection
      context = rule.context.name

      old_tags ||= []
      new_tags ||= []
      unchanged_tags  = old_tags & new_tags
      tags_removed    = old_tags - unchanged_tags
      tags_added      = new_tags - unchanged_tags


      tags_removed.each do |tag|
        coll.find(get_conditions(document, tag)).upsert({'$inc' => {value: -1}})
      end
      tags_added.each do |tag|
        coll.find(get_conditions(document, tag)).upsert({'$inc' => {value: 1}})
      end
      #coll.find({_id: {"$in" => tags_removed}}).update({'$inc' => {:value => -1}}, [:upsert])
      #coll.find({_id: {"$in" => tags_added}}).update({'$inc' => {:value => 1}}, [:upsert])
    end

    def get_conditions(document, tag)
      conditions = {tag_name_attribute.to_sym => tag}
      conditions.merge!({group: group_by_value(document)}) if rule.group_by
      conditions
    end

  end
end
