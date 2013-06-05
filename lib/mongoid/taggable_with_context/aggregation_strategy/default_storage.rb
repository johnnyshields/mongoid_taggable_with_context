# Tag aggregation data retrieval methods assuming data is stored in the database in a standard fashion



module Mongoid::TaggableWithContext::AggregationStrategy

  class InvalidTagQuery < Exception; end

  module DefaultStorage

    # returns array or hash (if grouped)

    # Collection name for storing results of tag count aggregation
    def tags(group = nil)


      find_results.to_a.map{ |t| t[tag_name_attribute] }
      # below is from group_by
      results.uniq
    end

    # returns array or hash (if grouped)

    # retrieve the list of tag with weight(count), this is useful for
    # creating tag clouds
    def tags_with_weight(group = nil)


      results = rule.collection.find(criteria).sort(tag_name_attribute.to_sym => 1)
      results = results.to_a.map{ |t| [t[tag_name_attribute], t['value'].to_i] }
      # below is from group_by
      tag_hash = {}
      results.each do |tag, weight|
        tag_hash[tag] ||= 0
        tag_hash[tag] += weight
      end
      tag_hash.to_a
    end

    # TODO: IS THIS A CLEANER API???
    # retrieves tags for a specific group
    #def tags_for_group(group)
    #
    #end
    #
    ## retrieves tags for a specific group
    #def tags_with_weight_for_group(group)
    #  raise InvalidTagQuery(':group_by not specified')
    #end

    def tags
      rule.collection.find({value: {'$gt' => 0 }}).sort(_id: 1).to_a.map{ |t| t['_id'] }
    end

    def tags_with_weight
      rule.collection.find({value: {'$gt' => 0 }}).sort(_id: 1).to_a.map{ |t| [t['_id'], t['value'].to_i] }
    end

    protected

    def find_results(group = nil)
      raise InvalidTagQuery(':group_by not specified') if group && !rule.group_by
      rule.collection.find(criteria(group)).sort(tag_name_attribute.to_sym => 1)
    end

    def criteria(group = nil)
      criteria = {}
      criteria[:value] = { '$gt' => 0 }
      criteria[:group] = rule.group_by if rule.group_by
      #criteria.merge!(rule.scope) if rule.scope # TODO ??
      criteria
    end
  end
end