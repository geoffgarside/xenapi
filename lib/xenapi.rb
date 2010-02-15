require 'uri'
require 'xmlrpc/client'

module XenApi #:nodoc:
  class Client
    class LoginRequired < RuntimeError; end
    class SessionInvalid < RuntimeError; end
    class ResponseMissingStatusField < RuntimeError; end
    class ResponseMissingValueField < RuntimeError; end
    class ResponseMissingErrorDescriptionField < RuntimeError; end

    def inspect
      "#<#{self.class} #{@uri}>"
    end

    def initialize(uri, timeout = 10)
      @timeout = timeout
      @uri = URI.parse(uri)
      @uri = URI.parse(uri + '/') if @uri.path == ''
    end
    def method_missing(meth, *args)
      case meth.to_s
      when /^login/
        _login(meth, *args)
      when /^async/i
        AsyncDispatcher.new(self, :_call)
      else
        Dispatcher.new(self, meth, :_call)
      end
    end
    protected
      def _call(meth, *args)
        args.unshift(@session) if @session
        begin
          _do_call(meth, args)
        rescue SessionInvalid
          _relogin
          _do_call(meth, args)
        rescue EOFError
          @client = nil
          _call(meth, *args)
        rescue Errno::EPIPE
          @client = nil
          _call(meth, *args)
        end
      end
    private
      def _relogin
        raise LoginRequired if @login_meth.nil? || @login_args.nil? || @login_args.empty?
        _login(@login_meth, *@login_args)
      end
      def _login(meth, *args)
        begin
          @session = _do_call("session.#{meth}", args)
          @login_meth = meth
          @login_args = args
          true
        rescue Exception => e
          raise e
        end
      end
      def _client
        @client ||= XMLRPC::Client.new(@uri.host, @uri.path, @uri.port, nil, nil, nil, nil, @uri.port == 443, @timeout)
      end
      def _do_call(meth, args, attempts = 3)
        r = _client.call(meth, *args)
        raise ResponseMissingStatusField unless r.has_key?('Status')

        if r['Status'] == 'Success'
          return r['Value'] if r.has_key?('Value')
          raise ResponseMissingStatusField
        else
          raise ResponseMissingErrorDescriptionField unless r.has_key?('ErrorDescription')
          raise SessionInvalid if r['ErrorDescription'][0] == 'SESSION_INVALID'
          raise r['ErrorDescription'].inspect
        end
      end
  end
  class Dispatcher
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
