require 'spec_helper'

describe 'deprecations' do
  context 'removed options' do
    context 'taggable options' do
      it 'should throw error if :field option is specified' do
        expect do
          class TaggableWithDeprecatedFieldOption
            include Mongoid::Document
            include Mongoid::TaggableWithContext
            taggable field: :foobar
          end
        end.to raise_error
      end
      it 'should throw error if :string_method option is specified' do
        expect do
          class TaggableWithDeprecatedStringMethodOption
            include Mongoid::Document
            include Mongoid::TaggableWithContext
            taggable string_method: :foobar
          end
        end.to raise_error
      end
      it 'should throw error if :group_by_field option is specified' do
        expect do
          class TaggableWithDeprecatedGroupByFieldOption
            include Mongoid::Document
            include Mongoid::TaggableWithContext
            taggable group_by_field: :foobar
          end
        end.to raise_error
      end
    end

    context 'modules' do
      it 'should throw error if GroupBy::TaggableWithContext module is included' do
        expect do
          class DeprecatedGroupBy
            include Mongoid::Document
            include Mongoid::TaggableWithContext::GroupBy::TaggableWithContext
          end
        end.to raise_error
      end
      it 'should throw error if GroupBy::AggregationStrategy::RealTime module is included' do
        expect do
          class DeprecatedGroupBy
            include Mongoid::Document
            include Mongoid::TaggableWithContext::GroupBy::AggregationStrategy::RealTime
          end
        end.to raise_error
      end
    end
  end
end