require 'spec_helper'

module Mongoid::TaggableWithContext::Taggable
  describe TagContext do
    subject{ TagContext.new }

    describe '#initialize' do
      context 'defaults' do
        its(:separator){ should eq(TagContext::DEFAULT_SEPARATOR)}
        its(:db_field){ should eq(TagContext::DEFAULT_FIELD)}
        its(:name){ should eq(TagContext::DEFAULT_FIELD)}
      end
      context 'with options' do
        subject{ TagContext.new(separator: ',', db_field: 'foo') }
        its(:separator){ should eq(',')}
        its(:db_field){ should eq(:foo)}
        its(:name){ should eq(:foo)}
        context 'with :as option' do
          subject{ TagContext.new(separator: ',', db_field: 'foo', as: 'bar') }
          its(:separator){ should eq(',')}
          its(:db_field){ should eq(:foo)}
          its(:name){ should eq(:bar)}
        end
      end
    end

    describe '#format_tags' do
      context 'when value is Array' do
        let(:value){ ['foo,bar  ', ' baz ', 'baz ', '   ', ' bar', 'bar', 'baz,,,qux'] }
        it 'should remove whitespace, blanks, and duplicates' do
          subject.format_tags(value).should == ["foo,bar", "baz", "bar", "baz,,,qux"]
        end
      end
      context 'when value is String' do
        let(:value){ 'foo,bar baz,bar   baz  bar  ,  bar   baz,,,qux cat,dog' }
        it 'should split and compact the string' do
          subject.format_tags(value).should == ["foo,bar", "baz,bar", "baz", "bar", ",", "baz,,,qux", "cat,dog"]
        end
        context 'when separator is explicitly set' do
          subject{ TagContext.new(separator: ',') }
          it 'should split and compact the string' do
            subject.format_tags(value).should == ["foo", "bar baz", "bar   baz  bar", "bar   baz", "qux cat", "dog"]
          end
        end
      end
      context 'when value is not Array or String' do
        let(:value){ {this: 'is', not: 'an', array: 'or string'} }
        it 'should raise an error' do
          expect{ subject.format_tags(value) }.to raise_error InvalidTagFormat
        end
      end
    end
  end
end