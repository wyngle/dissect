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
    yml = YAML.load_file(File.expand_path("spec/test_files/test.yml"))
    general_options = yml["general_options"]["data_classification"]
    # no multipart text email
    mailtext = Mail.read File.expand_path("spec/test_files/text.eml")
    # multipart - html
    mailhtml = Mail.read File.expand_path("spec/test_files/multipart.eml")
    # encoded
    mailenc = Mail.read File.expand_path("spec/test_files/encoded.eml")
    # multipart - xml
    mailxml  = Mail.read File.expand_path("spec/test_files/xml.eml")
    @plain_text = "phone number: 111-123-4567"
    input_type1 = "email"
    input_type2 = "xml"
    input_type3 = "text"
    arr = ["4", "11", "31", "14"]
    @str1 = Dissect::to_plaintext(mailhtml, input_type1)
    @str2 = Dissect::to_plaintext(mailxml, input_type2)
    @str3 = Dissect::to_plaintext(mailxml, input_type1)
    @str4 = Dissect::to_plaintext(mailtext, input_type1)
    @str5 = Dissect::to_plaintext(@plain_text, input_type3)
    @test_reg1 = Dissect::to_regexp("/^\D*\d\D*\d/i")
    @test_reg2 = Dissect::to_regexp("/^\D*\d\D*\d/x")
    @test_reg3 = Dissect::to_regexp("/^\D*\d\D*\d/m")
    @arr_to_reg = Dissect::array_to_regexp(arr)
  end


  describe '#to_plaintext' do
    it "returns the EMAIL in plain text" do
      @str1.should be_an_instance_of(String)
      @str1.should_not match(/<[^<!]*>/)
    end

    it "returns the XML in plain text" do
      @str2.should be_an_instance_of(String)
      @str2.should_not match(/<[^<!]*>/)
    end

    it "returns the text as text" do
      @str3.should_not match(/<[^<!]*>/)
    end

    it "should raise" do
      expect{Dissect::to_plaintext(mailenc, input_type1)}.to raise_error
    end

    it "should just return the body devoded" do
      @str4 == "\nDear Mr. User,\n\ntest body! just for @testing\n----"
    end

    it "should return the same string" do
      @str5 == @plain_text
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

  describe '#array_to_regexp' do
    it "returns one regex" do
      @arr_to_reg.should be_an_instance_of(Regexp)
      @arr_to_reg == /(.{4}?) (.{11}?) (.{31}?) (.{14}?) /
    end
  end

# ##############################################################################

  before :each do
    ar = ["a", "b", "c"]
    @hash = Hash[ar.collect { |v| [v, Dissect::EmptyHash.new(v)] }]
  end

  describe Dissect::EmptyHash do
  # describe '#empty_hash' do
    it "returns an empty hash" do
      @hash.should be_an_instance_of(Hash)
      @hash == {"a"=>"", "b"=>"", "c"=>""}
    end
  end

# ##############################################################################

  before :each do
    # ENV.stub(:[]).with("DISSECT_ROOT").and_return("/home/rp0/thegem")
    root = Dissect::root
    @path = Dissect::set_config_paths
    @gen_path = Dissect::set_generators_paths
    @dir = File.join(root, @path)
  end

  describe '#set_config_paths' do
    it "should eq the right path" do
      @path == "/config/dissect"
    end
  end

  describe '#set_generators_paths' do
    it "should eq the right path" do
      @gen_path == "dissect/lib/generators/dissect.yml"
    end
  end

  # describe '#set_config_dir' do
  #   it "must create the config directory" do
  #     Pathname(@dir).should exist
  #   end
  # end

# ##############################################################################

  before :each do
    yml = YAML.load_file(File.expand_path("spec/test_files/test.yml"))
    regexes = yml["unstructured"]["regexes"]
    @str     = "phone number: 111-123-4567"
    @str2    = "startt  1  AA00000     Superwow Item1 - version4          EUR 113.34
          ???O 113.34\n                 Edition\n  1  AA000000000 Superwow Item2
                           EUR 41.01       ???O 41.01\n     11           endd
            phone number: 111-123-4567"
    options = yml["structured"]["options"]
    @structure = options["structure"]

    @output = Dissect.unstructured_parser(regexes, @str)
    @output2 = Dissect.structured_parser(options, @structure, @str2)
    @result_json  = Dissect.result(@output, "json")
    @result_json2  = Dissect.result(@output2, "json")
    @result_xml   = Dissect.result(@output, "xml")

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

  describe '#structured_parser' do
    it "should return a hash with matches" do
      @output2.should be_an_instance_of(Hash)
    end
  end

  # it prints things -fix it
  describe '#result' do
    it "should be a correct json" do
      @result_json == @output.to_json
      @result_json2 == @output2.to_json
    end
    it "should be a  correct xml" do
      @result_xml.should match(/\<\?xml version/)
      # @result_xml.should have_selector("<?xml version=\"1.0\"?>")
    end
  end

# ##############################################################################

  before(:each) do
    Dissect.stub(:set_config_paths).and_return("spec/test_files/")
    Dissect.stub(:set_generators_paths).and_return("spec/test_files/test.yml")
    Dissect.stub(:root).and_return(File.expand_path '../..', __FILE__)
    @load = Dissect.regex_loader("test")
    @valid_i = Dissect.valid_identifier

    @empty_data = ""
    @final1 = Dissect.process(@str, ["test_un"], "text", "json")
    @final2 = Dissect.process(@str2, ["test"], "text", "json")
  end

  describe '#process' do
    it "should raise ArgumentError" do
      expect{ Dissect.process.validate_arguments(nil) }.to raise_error(ArgumentError)
    end

    # it "should have correct arguments" do
    #   Dissect.process.should_receive(:process).with(kind_of(String), kind_of(Array))
    # end
  end

  describe '#regex_loader' do
    it "should load yml contents to a hash" do
      @load.should be_an_instance_of(Hash)
    end
  end

  describe '#valid_identifier' do
    it "should return an array of available config files" do
      @valid_i.should be_an_instance_of(Array)
      @valid_i == ["test","test_un"]
    end
  end

  describe '#process' do
    it "should return the output hash to a json" do
      @final1 == @output
      @final2 == @output2
    end
  end

  describe '#process' do
    it "should raise error for nill data" do
      expect{ Dissect.process(@empty_data, ["test"], text) }.to raise_error
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

end
