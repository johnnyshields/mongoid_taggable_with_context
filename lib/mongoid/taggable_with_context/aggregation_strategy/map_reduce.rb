module Mongoid::TaggableWithContext::AggregationStrategy
  class MapReduce < Strategy
    include DefaultStorage

    def initialize(rule)
      super(rule)
      raise NotImplementedError.new(':group_by is not yet implemented for MapReduce') if rule.group_by
      raise NotImplementedError.new(':scope is not yet implemented for MapReduce') if rule.scope
    end

    def after_save(document)
      map_reduce! if context_changed?(document)
    end

    def after_destroy(document)
      map_reduce!
    end

    def recalculate!
      map_reduce!
    end

    protected

    # Executes a Mongoid map_reduce to aggregate the tags and tag weights.
    #
    # @return [ Float ] The execution time in milliseconds.
    #
    # @since 2.0.0
    def map_reduce!
      rule.model.map_reduce(map, reduce).out(replace: rule.collection_name).time
    end

    # Builds the 'map' MongoDB instruction to emit the tag values.
    #
    # @return [ String ] The 'map' MongoDB instruction.
    #
    # @since 2.0.0
    def map
      db_field = rule.context.db_field
      <<-END
        function() {
          if (!this.#{db_field})return;
          for (index in this.#{db_field})
            emit(this.#{db_field}[index], 1);
        }
      END
    end

    # Builds the 'reduce' MongoDB instruction to summarize the tag aggregation result.
    #
    # @return [ String ] The 'reduce' MongoDB instruction.
    #
    # @since 2.0.0
    def reduce
      <<-END
        function(key, values) {
          var count = 0;
          for (index in values) count += values[index];
          return count;
        }
      END
    end
  end
end
