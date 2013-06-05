require 'spec_helper'

module Mongoid::TaggableWithContext::Taggregation
  describe Rule do
    let(:model){ MyModel }
    let(:context){ :tags }
    let(:options){ {} }
    subject{ Rule.new(model, context, options) }

    describe '#initialize' do
      its(:model){ should eq(MyModel) }
      its(:context){ should eq(MyModel.tag_contexts[:tags]) }
      context 'with invalid tag context' do
        let(:context){ :foobar }
        it 'should raise TagContextNotFound error' do
          expect{ subject }.to raise_error TagContextNotFound
        end
      end
      context 'defaults' do
        its(:group_by){ should be_nil }
        its(:scope){ should be_nil }
        its(:options){ should == {} }
      end
      context 'with scope option' do
        let(:options){ {scope: ->{'bar'} } }
        its(:scope){ should be_a Proc }
      end
      context 'with group_by option' do
        let(:options){ {group_by: 'foo'} }
        its(:group_by){ should == 'foo' }
      end
    end

    describe '#name' do
      context 'without options' do
        its(:name){ should eq('tags') }
      end
      context 'without name option' do
        context 'with group_by option' do
          let(:options){ {group_by: 'foo'} }
          its(:name){ should eq('tags_by_foo') }
        end
        context 'with scope option' do
          let(:options){ {scope: ->{'bar'}} }
          its(:name){ should eq('tags_with_scope') }
        end
        context 'with strategy option' do
          let(:options){ {strategy: Mongoid::TaggableWithContext::AggregationStrategy::MapReduce} }
          its(:name){ should eq('tags_via_map_reduce') }
        end
        context 'with multiple options' do
          let(:options){ {group_by: 'foo', scope: ->{'bar'}, strategy: Mongoid::TaggableWithContext::AggregationStrategy::MapReduce} }
          its(:name){ should eq('tags_by_foo_with_scope_via_map_reduce') }
        end
      end
      context 'with name option' do
        context 'without tokens' do
          let(:options){ {name: 'foo'} }
          its(:name){ should eq('foo') }
        end
        context 'with tokens' do
          let(:options){ {name: 'my_%{context}_with_group_%{group_by}_and_strat_%{strategy}', group_by: 'foo', scope: ->{'bar'}, strategy: Mongoid::TaggableWithContext::AggregationStrategy::MapReduce} }
          its(:name){ should eq('my_tags_with_group_foo_and_strat_map_reduce') }
        end
      end
    end

    describe '#strategy' do
      it 'should memoize the strategy' do
        s = subject.strategy
        subject.strategy.should == s
      end
      context 'default' do
        its(:strategy){ should be_a(Rule::DEFAULT_STRATEGY) }
      end
      context 'when :strategy is a subclass of Strategy' do
        let(:options){ {strategy: Mongoid::TaggableWithContext::AggregationStrategy::MapReduce} }
        its(:strategy){ should be_a(Mongoid::TaggableWithContext::AggregationStrategy::MapReduce) }
      end
      context 'when :strategy is the Strategy class itself' do
        let(:options){ {strategy: Mongoid::TaggableWithContext::AggregationStrategy::Strategy} }
        it 'should raise InvalidStrategy error' do
          expect{ subject }.to raise_error InvalidStrategy
        end
      end
      context 'when :strategy is not a subclass of Strategy' do
        let(:options){ {strategy: Array} }
        it 'should raise InvalidStrategy error' do
          expect{ subject }.to raise_error InvalidStrategy
        end
      end
    end

    describe '#collection' do
      let(:database){ Moped::Database.new(model.collection.database, 'my_database') }
      let(:collection){ Moped::Collection.new(database, 'my_collection') }
      let(:default_collection_name){ "#{model.collection.name}_#{subject.name}_aggregation" }
      context 'default' do
        it 'should default to a named collection in model database' do
          subject.collection.database.name.should == model.collection.database.name
          subject.collection.name.should == default_collection_name
        end
      end
      context 'with a specified collection' do
        let(:options){ {collection: collection} }
        it 'should use the specified collection' do
          subject.collection.should == collection
        end
      end
      context 'with a specified database' do
        let(:options){ {database: database} }
        it 'should use the specified database and a default collection name' do
          subject.collection.name.should == default_collection_name
          subject.collection.database.should == database
        end
      end
      context 'with a specified collection name' do
        let(:options){ {collection_name: 'foobar'} }
        it 'should use the specified collection name and the model database' do
          subject.collection.name.should == 'foobar'
          subject.collection.database.name.should == model.collection.database.name
        end
      end
      context 'with a specified database and collection name' do
        let(:options){ {database: database, collection_name: 'foobar'} }
        it 'should use the specified database and collection name' do
          subject.collection.name.should == 'foobar'
          subject.collection.database.should == database
        end
      end
      context 'with all of collection, database, and collection name specified' do
        let(:options){ {collection: collection, database: database, collection_name: 'foobar'} }
        it 'should give priority to the collection' do
          subject.collection.should == collection
        end
      end
    end
  end
end