require 'spec_helper'

describe Ezid::Record do
  describe ".delete" do
    before(:all) do
      session = Ezid::ApiSession.new
      @mintedId = session.mint(Ezid::ApiSession::TESTMETADATA)
      doisession = Ezid::ApiSession.new(Ezid::ApiSession::TESTUSERNAME, Ezid::ApiSession::TESTPASSWORD, :doi)
      @mintedDoi = doisession.mint(Ezid::ApiSession::TESTMETADATA)
    end
    it "should succesfully delete an ark" do
      result = @mintedId.delete
      result.should be_kind_of Ezid::ServerResponse
      result.should_not be_errored
      @mintedId.delete.should be_errored
    end
    it "should succesfully delete a doi" do
      result = @mintedDoi.delete
      result.should be_kind_of Ezid::ServerResponse
      result.should_not be_errored
      @mintedDoi.delete.should be_errored
    end
  end
  describe ".[]=" do
    before(:each) do
      @session = Ezid::ApiSession.new
      @record = Ezid::Record.new(@session, 'blabla', {"Test" => 1, "Test2" => 3})
    end
    it "should allow you to set metadata" do
      @record["Test"] = 30
      @record["Test"].should == 30
      @record.metadata["Test"].should == 30
    end
    it "should add the key to changed" do
      @record["Test"] = 30
      @record.instance_variable_get(:@changed).should == ["Test"]
    end
  end
  describe ".save" do
    before(:each) do
      @session = Ezid::ApiSession.new
      @record = @session.mint({"Test" => 1, "Test2" => 3, "Test3" => 5})
      @record["Test"] = "blabla"
      @record["Test2"] = 36
    end
    after(:each) do
      @record.delete
    end
    it "should update all changed metadata" do
      @record.save
      newRecord = @session.get(@record.identifier)
      newRecord["Test"].should == "blabla"
    end
    it "should make the record stale" do
      @record.should_not be_stale
      @record.save
      @record.should be_stale
    end
  end
  describe ".make_public" do
    before(:each) do
      @session = Ezid::ApiSession.new
      @record = Ezid::Record.new(@session, 'blabla', {"Test" => 1, "Test2" => 3})
    end
    it "should set the status to public" do
      @record.make_public
      @record["_status"].should == Ezid::ApiSession::PUBLIC
    end
  end
  describe ".make_unavailable" do
    before(:each) do
      @session = Ezid::ApiSession.new
      @record = Ezid::Record.new(@session, 'blabla', {"Test" => 1, "Test2" => 3})
    end
    it "should set the status to unavailable" do
      @record.make_unavailable
      @record["_status"].should == Ezid::ApiSession::UNAVAIL
    end
  end
  describe ".persisted?" do
    before(:each) do
      @session = Ezid::ApiSession.new
      @record = Ezid::Record.new(@session,@session.build_identifier("blabla"),{"Test" => 1, "Test2" => 3})
    end
    after(:each) do
      @record.delete
    end
    it "should return false if an attribute has been changed" do
      @record["Test"] = 3
      @record.should_not be_persisted
    end
    it "should return true if an attribute is updated with its old value, and it was already persisted" do
      Ezid::ApiSession.any_instance.should_receive(:call_api).at_least(1).times.and_return(double("responseMock", :errored? => false))
      @record.save
      @record["Test"] = 1
      @record.should be_persisted
    end
    it "should return false if it was never saved" do
      @record.should_not be_persisted
    end
    it "should return true if it was saved" do
      Ezid::ApiSession.any_instance.should_receive(:call_api).at_least(1).times.and_return(double("responseMock", :errored? => false))
      @record.save
      @record.should be_persisted
    end
  end
  describe ".reload" do
    before(:each) do
      @session = Ezid::ApiSession.new
      @record = @session.mint({"Test" => "bla"})
    end
    after(:each) do
      @record.delete
    end
    it "should pull in new information" do
      @oldupdated = @record["_updated"]
      @record["Test"] = "Testing"
      @record.save
      @record.reload
      @record["_updated"].should_not == @oldupdated
    end
  end
end
