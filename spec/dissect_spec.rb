require 'test_helper'
require 'mail'

# Class String
#
describe String do

  before :each do
    @test = "ena duo 1 2 3".scan2 /^\D*(?<protos>\d)\D*(?<deuteros>\d)/
  end

  describe '#scan2' do
    it "returns an array" do
      @test.should == [{"protos"=>"1", "deuteros"=>"2"}]
    end
  end

end

# Module Dissect
#
describe Dissect do

  before :each do
    mail = Mail.read File.expand_path("spec/test_files/playorder.eml")
    @sender = Dissect::thesender(mail)
    @str = Dissect::to_plaintext(mail)
    @test_reg = Dissect::to_regexp("/^\D*\d\D*\d/i")
  end

  describe '#thesender' do
    it "returns the sender as string" do
      # @sender.should be_a(String)
      @sender.should == "play.com"
    end
  end

  describe '#to_plaintext' do
    it "returns the email in plain text" do
      @str.should_not match(/<[^<!]*>/)
      # @str.should be_nil?
    end
  end

  describe '#to_regexp' do
    it "returns regexp class with correct options" do
      @test_reg.should be_an_instance_of(Regexp)
      @test_reg == /^\D*\d\D*\d/i
    end
  end

   before :each do
    a="1", b="2", c="3", d="4", e="5", f="6"
    @res = Dissect::result(b,c,d,e,f).values.any? &:empty?
  end

  describe '#process' do
    it "returns no empty output values" do
      @res.should_not be_true
    end
  end

end

