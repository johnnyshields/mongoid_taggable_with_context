require 'spec_helper'

module Mongoid::TaggableWithContext::AggregationStrategy
  describe Strategy do
    let(:rule){ Mongoid::TaggableWithContext::Taggregation::Rule.new(MyModel, :tags) }
    subject{ Strategy.new(rule) }

    describe '#rule' do
      its(:rule){ should eq(rule) }
    end

    describe '#tags' do
      it 'should raise NotImplementedError error' do
        expect { subject.tags }.to raise_error NotImplementedError
      end
    end

    describe '#tags_with_weight' do
      it 'should raise NotImplementedError error' do
        expect { subject.tags_with_weight }.to raise_error NotImplementedError
      end
    end
  end
end