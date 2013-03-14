module Ezid
  class Record
    attr_reader :identifier, :metadata
    def initialize(session, identifier, metadata={},persisted=false)
      @identifier = identifier
      @metadata = metadata
      @session = session
      @changed = []
      @stale = false
      @persisted = persisted
      self
    end
    # There has to be a better way to do this.
    def reload
      if(self.stale?)
        newRecord = @session.get(@identifier)
        @identifier = newRecord.identifier
        @metadata = newRecord.metadata
        @stale = false
      end
      return self
    end
    def persisted?
      @changed.length != 0 ? false : @persisted
    end
    def [](attribute)
      @metadata[attribute]
    end
    def []=(attribute,value)
      if(@metadata[attribute] != value)
        @changed << attribute
        @changed.uniq!
      end
      @metadata[attribute] = value
    end
    def delete
      @session.delete(identifier)
    end
    # Returns true if the record has been saved but not reloaded.
    def stale?
      return @stale
    end
    def save
      return self if self.persisted?
      modifyData = @changed.each_with_object({}){|key, hash| hash[key] = @metadata[key]}
      request_uri = "/id/#{@identifier}"
      result = @session.send(:call_api,request_uri, :post, modifyData)
      if(result.errored?)
        raise "Unable to save - error: #{result.response}"
      end
      @persisted = true
      @stale = true
      @changed = []
      return self
    end
    # Utility Methods
    def make_public
      self["_status"] = Ezid::ApiSession::PUBLIC
    end

    def make_unavailable
      self["_status"] = Ezid::ApiSession::UNAVAIL
    end
    # Shortcut methods - leave behind from old implementation.
    def status
      self["_status"]
    end
    def target
      self["_target"]
    end
    def target=(value)
      self["_target"] = value
    end
    def profile
      self["_profile"]
    end
    def profile=(value)
      self["_profile"] = value
    end
  end
end