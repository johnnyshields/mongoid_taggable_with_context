require 'spec_helper'

describe Mongoid::TaggableWithContext do
  describe 'taggable' do
    let(:model){ MyModel.new }

    context 'default field value' do
      it 'should be nil for artists' do
        model.artists.should eql nil
      end

      it 'should be array for albums' do
        model.albums.should eql []
      end
    end

    context 'saving tags from plain text' do
      it 'should set tags from string' do
        model.tags = 'some new tag'
        model.tags.should == %w[some new tag]
      end

      it 'should set artists tags from string' do
        model.artists = 'some, new, tag'
        model.artists.should == %w[some new tag]
      end

      it 'should retrieve tags string' do
        model.tags = %w[some new tags]
        model.tags_string.should == 'some new tags'
      end

      it 'should retrieve artists string' do
        model.artists = %w[some new tags]
        model.artists_string.should == 'some, new, tags'
      end

      it 'should strip tags before put in array' do
        model.tags = 'now   with   some spaces   in places '
        model.tags.should == %w[now with some spaces in places]
      end

      it 'should remove repeated tags from string' do
        model.tags = 'some new tags some new tags'
        model.tags.should == %w[some new tags]
      end

      it 'should remove repeated tags from array' do
        model.tags = %w[some new tags some new tags]
        model.tags.should == %w[some new tags]
      end

      it 'should remove nil tags from array' do
        model.tags = ['some', nil, 'new', nil, 'tags']
        model.tags.should == %w[some new tags]
      end
    end

    context 'saving tags from array' do
      it 'should remove repeated tags from array' do
        model.tags = %w[some new tags some new tags]
        model.tags.should == %w[some new tags]
      end

      it 'should remove nil tags from array' do
        model.tags = ['some', nil, 'new', nil, 'tags']
        model.tags.should == %w[some new tags]
      end

      it 'should remove empty strings from array' do
        model.tags = %w(some  new  tags)
        model.tags.should == %w[some new tags]
      end

      it 'should allow tags to be set to nil' do
        model.tags = nil
        model.tags.should == nil
      end
    end

    context 'separators' do
      it 'should allow a custom separator' do
        MyModel.tag_contexts[:artists].separator.should == ', '
      end

      it 'should use a default separator' do
        MyModel.tag_contexts[:tags].separator.should == ' '
      end

      context 'class alias methods' do
        it 'should allow a custom separator' do
          MyModel.artists_separator.should == ', '
        end

        it 'should use a default separator' do
          MyModel.tags_separator.should == ' '
        end
      end
    end

    context 'no aggregation' do
      it 'should raise AggregationStrategyMissing exception when retrieving tags' do
        lambda{ MyModel.tags }.should raise_error(NoMethodError)
      end

      it 'should raise AggregationStrategyMissing exception when retrieving tags with weights' do
        lambda{ MyModel.tags_with_weight }.should raise_error(NoMethodError)
      end
    end

    context 'tagged_with' do
      let(:m1){ MyModel.create!(tags: 'food ant bee', artists: 'jeff greg mandy aaron andy') }
      let(:m2){ MyModel.create!(tags: 'juice food bee zip', artists: 'grant andrew andy') }
      let(:m3){ MyModel.create!(tags: 'honey strip food', artists: 'mandy aaron andy') }

      it 'should retrieve a list of documents' do
        (MyModel.tags_tagged_with('food').to_a - [m1, m2, m3]).should be_empty
        (MyModel.artists_tagged_with('aaron').to_a - [m1, m3]).should be_empty
      end
    end
  end
end