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
      @uri.path = '/' if @uri.path == ''
    end
    def after_login(&block)
      if block
        @after_login = block
      elsif @after_login
        case @after_login.arity
        when 1
          @after_login.call(self)
        else
          @after_login.call
        end
      end
      self
    end
    def xenapi_session
      @session
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
        begin
          _do_call(meth, args.dup.unshift(@session))
        rescue SessionInvalid
          _relogin
          retry
        rescue EOFError
          @client = nil
          retry
        rescue Errno::EPIPE
          @client = nil
          retry
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
          after_login
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
          raise Errors.exception_class_from_desc(r['ErrorDescription'].shift), r['ErrorDescription'].inspect
        end
      end
  end
end
