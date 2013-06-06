require 'spec_helper'

# TODO: test that two aggregations can point to the same collection for both realtime and mapreduce

describe Mongoid::TaggableWithContext do

  shared_examples_for 'aggregation' do
    context 'retrieving index' do
      context "when there's no tags'" do
        it 'should return an empty array' do
          puts klass.to_s
          klass.tags.should == []
          klass.artists.should == []

          klass.tags_with_weight.should == []
          klass.artists_with_weight == []
        end
      end

      context 'on create directly' do
        before :each do
          klass.create!(user: 'user1', tags: 'food ant bee', artists: 'jeff greg mandy aaron andy')
          klass.create!(user: 'user1', tags: 'juice food bee zip', artists: 'grant andrew andy')
          klass.create!(user: 'user2', tags: 'honey strip food', artists: 'mandy aaron andy')
        end
      
        it 'should retrieve the list of all saved tags distinct and ordered' do
          klass.tags.should == %w[ant bee food honey juice strip zip]
          klass.artists.should == %w[aaron andrew andy grant greg jeff mandy]
        end

        it 'should retrieve a list of tags with weight' do
          klass.tags_with_weight.should == [
            ['ant', 1],
            ['bee', 2],
            ['food', 3],
            ['honey', 1],
            ['juice', 1],
            ['strip', 1],
            ['zip', 1]
          ]
        
          klass.artists_with_weight.should == [
            ['aaron', 2],
            ['andrew', 1],
            ['andy', 3],
            ['grant', 1],
            ['greg', 1],
            ['jeff', 1],
            ['mandy', 2]
          ]
        end
      end
      
      context 'on new then change attributes directly' do
        before :each do
          m = klass.new
          m.tags = 'food ant bee'
          m.artists = 'jeff greg mandy aaron andy'
          m.save!
          
          m = klass.new
          m.tags = 'juice food bee zip'
          m.artists = 'grant andrew andy'
          m.save!

          m = klass.new
          m.tags = 'honey strip food'
          m.artists = 'mandy aaron andy'
          m.save!
        end
      
        it 'should retrieve the list of all saved tags distinct and ordered' do
          klass.tags.should == %w[ant bee food honey juice strip zip]
          klass.artists.should == %w[aaron andrew andy grant greg jeff mandy]
        end

        it 'should retrieve a list of tags with weight' do
          klass.tags_with_weight.should == [
            ['ant', 1],
            ['bee', 2],
            ['food', 3],
            ['honey', 1],
            ['juice', 1],
            ['strip', 1],
            ['zip', 1]
          ]
        
          klass.artists_with_weight.should == [
            ['aaron', 2],
            ['andrew', 1],
            ['andy', 3],
            ['grant', 1],
            ['greg', 1],
            ['jeff', 1],
            ['mandy', 2]
          ]
        end
      end
      
      context 'on create then update' do
        before :each do
          m1 = klass.create!(user: 'user1', tags: 'food ant bee', artists: 'jeff greg mandy aaron andy')
          m2 = klass.create!(user: 'user1', tags: 'juice food bee zip', artists: 'grant andrew andy')
          m3 = klass.create!(user: 'user2', tags: 'honey strip food', artists: 'mandy aaron andy')
          
          m1.tags = m1.tags + %w[honey strip shoe]
          m1.save!
          
          m3.artists = m3.artists + %w[grant greg gory]
          m3.save!
        end
      
        it 'should retrieve the list of all saved tags distinct and ordered' do
          klass.tags.should == %w[ant bee food honey juice shoe strip zip]
          klass.artists.should == %w[aaron andrew andy gory grant greg jeff mandy]
        end

        it 'should retrieve a list of tags with weight' do
          klass.tags_with_weight.should == [
            ['ant', 1],
            ['bee', 2],
            ['food', 3],
            ['honey', 2],
            ['juice', 1],
            ['shoe', 1],
            ['strip', 2],
            ['zip', 1]
          ]
        
          klass.artists_with_weight.should == [
            ['aaron', 2],
            ['andrew', 1],
            ['andy', 3],
            ['gory', 1],
            ['grant', 2],
            ['greg', 2],
            ['jeff', 1],
            ['mandy', 2]
          ]
        end
      end

      context 'on create, update, then destroy' do
        before :each do
          m1 = klass.create!(user: 'user1', tags: 'food ant bee', artists: 'jeff greg mandy aaron andy')
          m2 = klass.create!(user: 'user1', tags: 'juice food bee zip', artists: 'grant andrew andy')
          m3 = klass.create!(user: 'user2', tags: 'honey strip food', artists: 'mandy aaron andy')
          
          m1.tags = m1.tags + %w[honey strip shoe] - %w[food]
          m1.save!
          
          m3.artists = m3.artists + %w[grant greg gory] - %w[andy]
          m3.save!
          
          m2.destroy
        end
      
        it 'should retrieve the list of all saved tags distinct and ordered' do
          klass.tags.should == %w[ant bee food honey shoe strip]
          klass.artists.should == %w[aaron andy gory grant greg jeff mandy]
        end

        it 'should retrieve a list of tags with weight' do
          klass.tags_with_weight.should == [
            ['ant', 1],
            ['bee', 1],
            ['food', 1],
            ['honey', 2],
            ['shoe', 1],
            ['strip', 2]
          ]
        
          klass.artists_with_weight.should == [
            ['aaron', 2],
            ['andy', 1],
            ['gory', 1],
            ['grant', 1],
            ['greg', 2],
            ['jeff', 1],
            ['mandy', 2]
          ]
        end
      end
    end
  end

  context 'map-reduce aggregation' do
    let(:klass) { M1 }
    it_should_behave_like 'aggregation'

    it 'should generate the tags aggregation collection name correctly' do
      klass.tags_via_map_reduce_aggregation_collection.should == 'm1s_tags_via_map_reduce_aggregation'
      klass.aggregation_collection_for(:tags_via_map_reduce).should == 'm1s_tags_via_map_reduce_aggregation'
    end
    
    it 'should generate the artists aggregation collection name correctly' do
      klass.artists_via_map_reduce_aggregation_collection.should == 'm1s_artists_via_map_reduce_aggregation'
      klass.aggregation_collection_for(:artists_via_map_reduce).should == 'm1s_artists_via_map_reduce_aggregation'
    end
  end
  
  context 'realtime aggregation' do
    let(:klass) { M2 }
    it_should_behave_like 'aggregation'

    it 'should generate the tags aggregation collection name correctly' do
      klass.aggregation_collection_for(:tags).should == 'm2s_tags_aggregation'
    end
    
    it 'should generate the artists aggregation collection name correctly' do
      klass.aggregation_collection_for(:artists).should == 'm2s_artists_aggregation'
    end
  end

  context 'realtime aggregation group by' do
    let(:klass) { M3 }
    it_should_behave_like 'aggregation'

    it 'should have artists_group_by value :user' do
      klass.artists_group_by.should == :user
    end

    it 'should generate the tags aggregation collection name correctly' do
      klass.aggregation_collection_for(:tags).should == 'm3s_tags_aggregation'
    end

    it 'should generate the artists aggregation collection name correctly' do
      klass.aggregation_collection_for(:artists).should == 'm3s_artists_aggregation'
    end

    context 'for groupings' do
      before :each do
        klass.create!(user: 'user1', tags: 'food ant bee', artists: 'jeff greg mandy aaron andy')
        klass.create!(user: 'user1', tags: 'juice food bee zip', artists: 'grant andrew andy')
        klass.create!(user: 'user2', tags: 'honey strip food', artists: 'mandy aaron andy')
      end

      it 'should retrieve the list of all saved tags distinct and ordered' do
        klass.tags('user1').should == %w[ant bee food juice zip]
        klass.tags('user2').should == %w[food honey strip]

        klass.artists('user1').should == %w[aaron andrew andy grant greg jeff mandy]
        klass.artists('user2').should == %w[aaron andy mandy]
      end

      it 'should retrieve a list of tags with weight' do
        klass.tags_with_weight('user1').should == [
            ['ant', 1],
            ['bee', 2],
            ['food', 2],
            ['juice', 1],
            ['zip', 1]
        ]

        klass.tags_with_weight('user2').should == [
            ['food', 1],
            ['honey', 1],
            ['strip', 1]
        ]

        klass.artists_with_weight('user1').should == [
            ['aaron', 1],
            ['andrew', 1],
            ['andy', 2],
            ['grant', 1],
            ['greg', 1],
            ['jeff', 1],
            ['mandy', 1]
        ]

        klass.artists_with_weight('user2').should == [
            ['aaron', 1],
            ['andy', 1],
            ['mandy', 1]
        ]
      end
    end
  end

  context 'a taggregation without its taggable field' do
    it 'should raise an taggable field missing error' do
      expect do
        class Invalid
          include Mongoid::Document
          include Mongoid::TaggableWithContext
          taggable
          taggregation :foobar
        end
      end.to raise_error(Mongoid::TaggableWithContext::Taggregation::TagContextNotFound)
    end
  end

  context 'taggregation without valid taggable context' do
    it 'should be invalid' do
      expect do
        class TaggableDefinedAfterTaggregation
          include Mongoid::Document
          include Mongoid::TaggableWithContext

          taggable
          taggregation :artists
        end
      end.to raise_error Mongoid::TaggableWithContext::Taggregation::TagContextNotFound
    end
  end

  context 'taggable after taggregation' do
    context 'context-specific taggregation' do
      it 'should be valid' do
        expect do
          class TaggableDefinedAfterSpecificTaggregation
            include Mongoid::Document
            include Mongoid::TaggableWithContext

            taggable :a, as: :artists
            taggregation :artists
            taggable
          end
        end.to_not raise_error
      end
    end
    context 'context-unspecific taggregation' do
      it 'should be invalid' do
        expect do
          class TaggableDefinedAfterGlobalTaggregation
            include Mongoid::Document
            include Mongoid::TaggableWithContext

            taggable
            taggregation
            taggable :a, as: :artists
          end
        end.to raise_error Mongoid::TaggableWithContext::Taggable::TaggableAfterGlobalTaggregation
      end
    end
  end
end
