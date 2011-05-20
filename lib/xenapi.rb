module XenApi #:nodoc:
  autoload :Client,           File.expand_path('../xenapi/client',            __FILE__)
  autoload :Errors,           File.expand_path('../xenapi/errors',            __FILE__)
  autoload :Dispatcher,       File.expand_path('../xenapi/dispatcher',        __FILE__)
  autoload :AsyncDispatcher,  File.expand_path('../xenapi/async_dispatcher',  __FILE__)
end
