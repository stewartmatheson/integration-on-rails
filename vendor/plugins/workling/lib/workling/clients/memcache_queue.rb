#
#  This client can be used for all Queue Servers that speak Memcached, such as Starling. 
#
#  Wrapper for the memcache connection. The connection is made using fiveruns-memcache-client, 
#  or memcache-client, if this is not available. See the README for a discussion of the memcache 
#  clients. 
#
#  method_missing delegates all messages through to the underlying memcache connection. 
#
module Workling
  module Clients
    class MemcacheQueue
      
      # the class with which the connection is instantiated
      cattr_accessor :memcache_client_class
      @@memcache_client_class ||= ::MemCache
      
      # the url with which the memcache client expects to reach starling
      attr_accessor :queueserver_urls
      
      # the memcache connection object
      attr_accessor :connection
      
      #
      #  the client attempts to connect to queueserver using the configuration options found in 
      #
      #      Workling.config. this can be configured in config/workling.yml. 
      #
      #  the initialization code will raise an exception if memcache-client cannot connect 
      #  to queueserver.
      #
      def initialize
        @queueserver_urls = Workling.config[:listens_on].split(',').map { |url| url ? url.strip : url }
        options = [@queueserver_urls, Workling.config[:memcache_options]].compact
        @connection = MemcacheQueue.memcache_client_class.new(*options)
        
        raise_unless_connected!
      end
      
      # delegates directly through to the memcache connection. 
      def method_missing(method, *args)
        @connection.send(method, *args)
      end
      
      private
        # make sure we can actually connect to queueserver on the given port
        def raise_unless_connected!
          begin 
            @connection.stats
          rescue
            raise Workling::QueueserverNotFoundError.new
          end
        end
    end
  end
end