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
    mailhtml = Mail.read File.expand_path("spec/test_files/playorder.eml")
    mailxml  = Mail.read File.expand_path("spec/test_files/playorder.eml")
    input_type1 = "email"
    input_type2 = "xml"
    @str1 = Dissect::to_plaintext(mailhtml, input_type1)
    @str2 = Dissect::to_plaintext(mailxml, input_type2)
    @test_reg1 = Dissect::to_regexp("/^\D*\d\D*\d/i")
    @test_reg2 = Dissect::to_regexp("/^\D*\d\D*\d/x")
    @test_reg3 = Dissect::to_regexp("/^\D*\d\D*\d/m")
  end

# TODO
# put a multipart test_email and a bare one
  describe '#to_plaintext' do
    it "returns the EMAIL in plain text" do
      @str1.should_not match(/\A<[^<!]*>\z/)
    end
  end

  describe '#to_plaintext' do
    it "returns the XML in plain text" do
      @str2.should_not match(/<[^<!]*>/)
    end
  end

  describe '#to_regexp' do
    it "returns regexp class with correct options" do
      @test_reg1.should be_an_instance_of(Regexp)
      @test_reg2.should be_an_instance_of(Regexp)
      @test_reg3.should be_an_instance_of(Regexp)
      @test_reg1 == /^\D*\d\D*\d/i
      @test_reg2 == /^\D*\d\D*\d/x
      @test_reg3 == /^\D*\d\D*\d/m
    end
  end

  before :each do
    ar = ["a", "b", "c"]
    @hash = Hash[ar.collect { |v| [v, Dissect::empty_hash(v)] }]
  end

  describe '#empty_hash' do
    it "returns an empty hash" do
      @hash.should be_an_instance_of(Hash)
      @hash == {"a"=>"", "b"=>"", "c"=>""}
    end
  end

  before :each do
    root = Dissect::root
    @path = File.join(root, "/config/dissect")
  end

  describe '#process' do
    it "must create the config directory" do
      Pathname(@path).should exist
    end
  end

  describe '#process' do
    specify 'works when I do stub' do
      Dissect.should_receive(:process)
      Dissect.process("a",["2"],"b","c")
    end
  end

  before :each do
    @regexes = YAML.load_file(File.expand_path("spec/test_files/test.yml"))["non_fixed_structure"]["regexes"]
    str     = "phone number: 111-123-4567"
    @output = Dissect.unstructured_parser(@regexes, str)
    @result_json  = Dissect.result(@output, "json")
    # @result_xml   = Dissect.result(@output, "xml")
  end

  describe '#unstructured_parser' do
    it "should return a hash with matches" do
      @output.should be_an_instance_of(Hash)
      @output == {"named_cg"=>{"first_digits"=>"111", "second_digits"=>"123", "third_digits"=>"4567"},
      "non_named_cg"=>"4",
      "one_named_cg"=>"4567",
      "none_named_cg"=>["111", "123", "4567"],
      "no_cg"=>[" ", ":", " ", "-", "-"]}
    end
  end

  # it prints things -fix it
  describe '#result' do
    it "should be a correct json" do
      @result_json == @output.to_json
    end
    # it "should be a  correct xml" do
    #   @result_xml.should have_tag("<content>")
    # end
  end

  describe '#process' do
    it "should raise ArgumentError" do
      expect{ Dissect.process.validate_arguments(nil) }.to raise_error(ArgumentError)
    end
  end

  # describe '#process' do
  #   # process.should_receive(:identifier).with(instance_of(Array) )
  #   it "should have correct arguments" do
  #     # Dissect.process.should_receive(:identifier).with(1, kind_of(Array), "b")
  #     Dissect.process.should_receive(:identifier).with(kind_of(Array))
  #   end
  #   # Dissect.process("a",["2"],"b","c")
  # end
  # describe '#process' do
  #   it "should raise ArgumentError for arguments that are not boolean" do
  #     expect{ Foo.validate_arguments(nil) }.to raise_error(ArgumentError)
  # end

  # before :each do
  #   a="1", b="2", c="3", d="4", e="5", f="6"
  #   @res = Dissect::result(b,c,d,e,f).values.any? &:empty?
  # end

  # describe '#process' do
  #   it "returns no empty output values" do
  #     @res.should_not be_true
  #   end
  # end

end

