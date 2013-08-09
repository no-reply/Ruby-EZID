require 'spec_helper'

describe Ezid::ApiSession do
  describe ".initialize" do
    context "when given no arguments" do
      subject{Ezid::ApiSession.new}
      it "should use the test API account" do
        subject.instance_variable_get(:@pass).should == Ezid::ApiSession::TESTPASSWORD
        subject.instance_variable_get(:@user).should == Ezid::ApiSession::TESTUSERNAME
      end
      it "should default to the ark scheme" do
        subject.instance_variable_get(:@scheme).should == 'ark:/'
      end
    end
    context "when given a testusername" do
      subject{Ezid::ApiSession.new(Ezid::ApiSession::TESTUSERNAME,"nottestpassword")}
      it "should force a testpassword" do
        subject.instance_variable_get(:@pass).should == Ezid::ApiSession::TESTPASSWORD
      end
    end
  end
  describe ".mint" do
    it "should mint an ark" do
      session = Ezid::ApiSession.new
      mintedArk = session.mint(Ezid::ApiSession::TESTMETADATA)
      mintedArk.should be_kind_of Ezid::Record
      mintedArk.identifier.should start_with "#{session.instance_variable_get(:@scheme)}#{session.instance_variable_get(:@naa)}"
    end
    it "should mint a doi" do
      doisession = Ezid::ApiSession.new(Ezid::ApiSession::TESTUSERNAME, Ezid::ApiSession::TESTPASSWORD, :doi)
      mintedDoi = doisession.mint(Ezid::ApiSession::TESTMETADATA)
      mintedDoi.should be_kind_of Ezid::Record
      mintedDoi.identifier.should start_with "#{doisession.instance_variable_get(:@scheme)}#{doisession.instance_variable_get(:@naa)}"
    end
  end
  describe ".build_identifier" do
    before(:all) do
      @session = Ezid::ApiSession.new
      @doisession = Ezid::ApiSession.new(Ezid::ApiSession::TESTUSERNAME, Ezid::ApiSession::TESTPASSWORD, :doi)
    end
    it "should generate an ark" do
      id = @session.build_identifier('someid')
      id.should match(/^ark:\/[0-9]{5,}\/[^\/]+(\/.+)?/)
    end
    it "should generate a doi" do
      id = @doisession.build_identifier('someid')
      id.should match(/^(doi|DOI):10\.[0-9]{4}\/.+/)
    end
  end
  describe ".create" do
    before(:all) do
      @session = Ezid::ApiSession.new
      #Make sure the identifier is deleted first.
      if((a = @session.get(@session.build_identifier("monkeys"))).kind_of?(Ezid::Record))
        a.delete
      end
      @mintedId = @session.create("monkeys",Ezid::ApiSession::TESTMETADATA)
      @mintedId.should be_kind_of Ezid::Record
    end
    after(:all) do
      @mintedId.delete
    end
    it "should create an ark with the given identifier" do
      @mintedId.identifier.should == @session.build_identifier("monkeys")
    end
  end
  #I'm not sure how to test this more appropriately - all the mint/create methods return the result of get() on success
  describe ".get" do
    before(:all) do
      @session = Ezid::ApiSession.new
      @mintedId = @session.mint(Ezid::ApiSession::TESTMETADATA)
    end
    after(:all) do
      @mintedId.delete
    end
    # This will have to be changed if EZID ever starts appending more metadata.
    it "should return a record object with the correct metadata" do
      @mintedId.should be_kind_of Ezid::Record
    end
    it "should return a record object with appropriate metadata" do
      @mintedId.metadata.reject{|k,v| ["_created","_export","_owner","_ownergroup","_profile","_updated"].include? k}.should == @session.transform_metadata(Ezid::ApiSession::TESTMETADATA)
    end
  end
end
