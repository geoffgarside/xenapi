require 'uri'
require 'xmlrpc/client'

module XenApi #:nodoc:
  # This class permits the invocation of XMLRPC API calls
  # through a ruby-like interface
  #
  #   client = XenApi::Client.new('http://xenapi.test')
  #   client.login_with_password('root', 'password')
  #   client.VM.get_all
  #
  # == Authenticating with the API
  # Authentication with the API takes place through the API
  # +session+ class, usually using the +login_with_password+
  # method. The +Client+ handles this method specially to
  # enable it to retain the session identifier to pass to
  # invoked methods and perform reauthentication should the
  # session become stale.
  #
  #   client = XenApi::Client.new('http://xenapi.test')
  #   client.login_with_password('root', 'password')
  #
  # It is worth noting that only +login*+ matching methods
  # are specially passed through to the +session+ class.
  #
  # == Running code after API login
  # The +Client+ provides the ability for running code
  # after the client has successfully authenticated with
  # the API. This is useful for either logging authentication
  # or for registering for certain information from the API.
  #
  # The best example of this is when needing to make use of
  # the Xen API +event+ class for asynchronous event handling.
  # To use the API +event+ class you first have to register
  # your interest in a specific set of event types.
  #
  #   client = XenApi::Client.new('http://xenapi.test')
  #   client.after_login do |c|
  #     c.event.register %w(vm) # register for 'vm' events
  #   end
  #
  # == Asynchronous Methods
  # To call asynchronous methods on the Xen XMLRPC API you
  # first call +Async+ on the +Client+ instance followed by
  # the normal method name.
  # For example:
  #
  #   client = XenApi::Client.new('http://xenapi.test')
  #   client.login_with_password('root', 'password')
  #   client.Async.VM.get_all
  #   client.async.VM.get_all
  #
  # Calling either +Async+ or +async+ will work as the
  # capitalised form will always be sent when calling
  # a method asynchronously.
  class Client
    # The +LoginRequired+ exception is raised when
    # an API request requires login and no login
    # credentials have yet been provided.
    #
    # If you don't perform a login before receiving this
    # exception then you will want to catch it, log into
    # the API and then retry your request.
    class LoginRequired < RuntimeError; end

    # The +SessionInvalid+ exception is raised when the
    # API session has become stale or is otherwise invalid.
    #
    # Internally this exception will be handled a number of
    # times before being raised up to the calling code.
    class SessionInvalid < RuntimeError; end

    # The +ResponseMissingStatusField+ exception is raised
    # when the XMLRPC response is missing the +Status+ field.
    # This typically indicates an unrecoverable error with
    # the API itself.
    class ResponseMissingStatusField < RuntimeError; end

    # The +ResponseMissingValueField+ exception is raised
    # when the XMLRPC response is missing the +Value+ field.
    # This typically indicates an unrecoverable error with
    # the API itself.
    class ResponseMissingValueField < RuntimeError; end

    # The +ResponseMissingErrorDescriptionField+ exception
    # is raised when an error is returned in the XMLRPC
    # response, but the type of error cannot be determined
    # due to the lack of the +ErrorDescription+ field.
    class ResponseMissingErrorDescriptionField < RuntimeError; end

    # @see Object#inspect
    def inspect
      "#<#{self.class} #{@uri}>"
    end

    # @param [String] uri URL to the Xen API endpoint
    # @param [Integer] timeout Maximum number of seconds to wait for an API response
    def initialize(uri, timeout = 10)
      @timeout = timeout
      @uri = URI.parse(uri)
      @uri.path = '/' if @uri.path == ''
    end

    # @overload after_login
    #   Adds a block to be called after successful login to the XenAPI.
    #   @note The block will be called whenever the receiver has to authenticate
    #     with the XenAPI. This includes the first time the receiver recieves a
    #     +login_*+ method call and any time the session becomes invalid.
    #   @yield client
    #   @yieldparam [optional, Client] client Client instance
    # @overload after_login
    #   Calls the created block, this is primarily for internal use only
    # @return [Client] receiver
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

    # Returns the current session identifier.
    #
    # @return [String] session identifier
    def xenapi_session
      @session
    end

    # Handle API method calls.
    #
    # If the method called starts with +login+ then the method is
    # assumed to be part of the +session+ namespace and will be
    # called directly. For example +login_with_password+
    #
    #   client = XenApi::Client.new('http://xenapi.test/')
    #   client.login_with_password('root', 'password)
    #
    # If the method called is +async+ then an +AsyncDispatcher+
    # will be created to handle the asynchronous API method call.
    #
    #   client = XenApi::Client.new('http://xenapi.test/')
    #   client.async.host.get_servertime(ref)
    #
    # The final case will create a +Dispatcher+ to handle the
    # subsequent method call such as.
    #
    #   client = XenApi::Client.new('http://xenapi.test/')
    #   client.host.get_servertime(ref)
    #
    # @note +meth+ names are not validated
    #
    # @param [String,Symbol] meth Method name
    # @param [...] args Method args
    # @return [true,AsyncDispatcher,Dispatcher]
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
      # @param [String,Symbol] meth API method to call
      # @param [Array] args Arguments to pass to the method call
      # @raise [SessionInvalid] Reauthentication failed
      # @raise [LoginRequired] Authentication required, unable to login automatically
      # @raise [EOFError] XMLRPC::Client exception
      # @raise [Errno::EPIPE] XMLRPC::Client exception
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
      # Reauthenticate with the API
      # @raise [LoginRequired] Missing authentication credentials
      def _relogin
        raise LoginRequired if @login_meth.nil? || @login_args.nil? || @login_args.empty?
        _login(@login_meth, *@login_args)
      end

      # Login to the API
      #
      # @note Will call the +after_login+ block if login is successful
      #
      # @param [String,Symbol] meth Login method name
      # @param [...] args Arguments to pass to the login method
      # @return [Boolean] true
      # @raise [Exception] any exception raised by +_do_call+ or +after_login+
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

      # Return or initialize new +XMLRPC::Client+
      #
      # @return [XMLRPC::Client] XMLRPC client instance
      def _client
        @client ||= XMLRPC::Client.new(@uri.host, @uri.path, @uri.port, nil, nil, nil, nil, @uri.port == 443, @timeout)
      end

      # Perform XMLRPC method call.
      #
      # @param [String,Symbol] meth XMLRPC method to call
      # @param [Array] args XMLRPC method arguments
      # @param [Integer] attempts Number of times to retry the call, presently unused
      # @return [Object] method return value
      # @raise [ResponseMissingStatusField] XMLRPC response does not have a +Status+ field
      # @raise [ResponseMissingValueField] XMLRPC response does not have a +Value+ field
      # @raise [ResponseMissingErrorDescriptionField] API response error missing +ErrorDescription+ field
      # @raise [SessionInvalid] API session has expired
      # @raise [Errors::GenericError] API method specific error
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
