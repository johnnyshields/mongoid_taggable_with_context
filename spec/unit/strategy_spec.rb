require 'spec_helper'

module Mongoid::TaggableWithContext::AggregationStrategy
  describe Strategy do
    let(:rule){ Mongoid::TaggableWithContext::Taggregation::Rule.new(MyModel, :tags, rule_options) }
    let(:rule_options){ {} }
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

    let(:document){ double('document') }

    describe '#context_changed?' do
      context 'changes do not include context field' do
        before{ document.stub(:changes){ {} } }
        it 'should not consider the context changed' do
          subject.send(:context_changed?, document).should be_false
        end
      end
      context 'changes include context field' do
        before{ document.stub(:changes){ {'tags' => 'foo'} } }
        it 'should consider the context changed' do
          subject.send(:context_changed?, document).should be_true
        end
      end
    end

    describe '#context_changes' do
      context 'changes do not include context field' do
        before{ document.stub(:changes){ {} } }
        it 'should return nil' do
          subject.send(:context_changes, document).should be_nil
        end
      end
      context 'changes include context field' do
        before{ document.stub(:changes){ {'tags' => 'foo'} } }
        it 'should return the change value' do
          subject.send(:context_changes, document).should == 'foo'
        end
      end
    end

    describe '#context_value' do
      before{ document.stub(:tags){ 'foo' } }
      it 'should return the field value' do
        subject.send(:context_value, document).should == 'foo'
      end
    end

    describe '#group_by_value' do
      let(:rule_options){ {group_by: 'baz'} }
      before{ document.stub(:baz){ 'foo' } }
      it 'should return the field value' do
        subject.send(:group_by_value, document).should == 'foo'
      end
    end
  end
end