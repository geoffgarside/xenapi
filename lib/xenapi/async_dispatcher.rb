module XenApi #:nodoc:
  class AsyncDispatcher
    def initialize(client, sender)
      @client = client
      @sender = sender
    end
    def inspect
      "#<#{self.class}>"
    end
    def method_missing(meth, *args)
      Dispatcher.new(@client, "Async.#{meth}", @sender)
    end
  end  
end
