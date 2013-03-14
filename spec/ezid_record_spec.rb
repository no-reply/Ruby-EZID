require 'spec_helper'

describe Ezid::Record do
  describe ".delete" do
    before(:all) do
      @session = Ezid::ApiSession.new
      @mintedId = @session.mint(Ezid::ApiSession::TESTMETADATA)
    end
    it "should succesfully delete the ID" do
      result = @mintedId.delete
      result.should be_kind_of Ezid::ServerResponse
      result.should_not be_errored
      @mintedId.delete.should be_errored
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
end