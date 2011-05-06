module XenApi #:nodoc:
  class Dispatcher
    undef :clone

    def initialize(client, prefix, sender)
      @client = client
      @prefix = prefix
      @sender = sender
    end
    def inspect
      "#<#{self.class} #{@prefix}>"
    end
    def method_missing(meth, *args)
      @client.send(@sender, "#{@prefix}.#{meth}", *args)
    end
  end
end
