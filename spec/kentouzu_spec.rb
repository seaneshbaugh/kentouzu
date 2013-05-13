# encoding: utf-8
require 'spec_helper.rb'

describe Kentouzu do
  describe 'Sanity Test' do
    it 'should be a Module' do
      Kentouzu.should be_a(Module)
    end
  end
end
