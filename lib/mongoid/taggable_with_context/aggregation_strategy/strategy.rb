module Mongoid::TaggableWithContext::AggregationStrategy
  class Strategy
    attr_reader :rule

    def initialize(rule)
      @rule = rule
    end

    # The Strategy subclass should define one or more of the following methods,
    # which will be automatically triggered on the Model:
    #
    #    - after_create(document)
    #    - after_update(document)
    #    - after_upsert(document)
    #    - after_save(document)
    #    - after_destroy(document)



    # retrieve the list of tags
    def tags
      raise NotImplementedError
    end

    # retrieve the list of tag with weight(count), this is useful for
    # creating tag clouds
    def tags_with_weight
      raise NotImplementedError
    end

    def recalculate!
      raise NotImplementedError
    end

    protected

    # Helper method to determine if tag context field has changed in a given
    # document (using Mongoid dirty tracking.)
    #
    # @return [ Boolean ] Whether the tag context field has changed.
    #
    # @since 2.0.0
    def context_changed?(document)
      document.changes.keys.map(&:to_sym).include? rule.context.db_field
    end

    def context_changes(document)
      document.changes.with_indifferent_access[rule.context.db_field]
    end

    def context_value(document)
      document.send(rule.context.name)
    end

    def group_by_value(document)
      document.send(rule.group_by)
    end
  end
end
