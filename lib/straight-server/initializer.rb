module StraightServer

  class Initializer

    GEM_ROOT = File.expand_path('../..', File.dirname(__FILE__))
    MIGRATIONS_ROOT = GEM_ROOT + '/db/migrations/'

    attr_accessor :routes

    module ConfigDir

      @@config_dir = nil

      # Determine config dir or set default. Useful when we want to
      # have different settings for production or staging or development environments.
      def self.set!(path=nil)
        return if @@config_dir && path.nil?
        @@config_dir = path and return if path
        @@config_dir = ENV['HOME'] + '/.straight'
        ARGV.each do |a|
          # FIXME: = can be space; space can absent in the short version
          # FIXME: what if it's an argument for a parent project, where straight-server is just a library?
          if a =~ /\A--config-dir=.+/
            @@config_dir = File.expand_path(a.sub('--config-dir=', ''))
            break
          elsif a =~ /\A-c .+/
            @@config_dir = File.expand_path(a.sub('-c ', ''))
            break
          end
        end
        puts "Setting config dir to #{@@config_dir}"
      end

      def self.path
        @@config_dir
      end
    end

    def prepare(run_migrations: true)
      ConfigDir.set!
      create_config_files
      read_config_file
      yield StraightServer::Config if block_given?
      create_logger
      connect_to_db
      self.run_migrations if run_migrations && migrations_pending?
      # DB connection should be established and tables should be present before the models definition
      require_relative 'gateway'
      GatewayOnConfig.load_from_config
      require_relative 'transaction'
      require_relative 'order'
      setup_redis_connection
    end

    def add_route(path, &block)
      (self.routes ||= {})[path] = block
    end

    def create_config_files
      FileUtils.mkdir_p(ConfigDir.path) unless File.exist?(ConfigDir.path)

      unless File.exist?(ConfigDir.path + '/addons.yml')
        puts "\e[1;33mNOTICE!\e[0m \e[33mNo file #{ConfigDir.path}/addons.yml was found. Created an empty sample for you.\e[0m"
        puts "No need to restart until you actually list your addons there. Now will continue loading StraightServer."
        FileUtils.cp(GEM_ROOT + '/templates/addons.yml', ConfigDir.path)
      end

      unless File.exist?(ConfigDir.path + '/server_secret')
        puts "\e[1;33mNOTICE!\e[0m \e[33mNo file #{ConfigDir.path}/server_secret was found. Created one for you.\e[0m"
        puts "No need to restart so far. Now will continue loading StraightServer."
        File.open(ConfigDir.path + '/server_secret', "w") do |f|
          f.puts String.random(16)
        end
      end

      unless File.exist?(ConfigDir.path + '/config.yml')
        puts "\e[1;33mWARNING!\e[0m \e[33mNo file #{ConfigDir.path}/config.yml was found. Created a sample one for you.\e[0m"
        puts "You should edit it and try starting the server again.\n"

        FileUtils.cp(GEM_ROOT + '/templates/config.yml', ConfigDir.path)
        puts "Shutting down now.\n\n"
        exit
      end

    end

    def read_config_file
      YAML.load_file(ConfigDir.path + '/config.yml').each do |k,v|
        StraightServer::Config.send(k + '=', v)
      end
      StraightServer::Config.server_secret = File.read(ConfigDir.path + '/server_secret').chomp
    end

    def connect_to_db

      # symbolize keys for convenience
      db_config = StraightServer::Config.db.keys_to_sym

      db_name = if db_config[:adapter] == 'sqlite'
        db_config[:name].empty? ? '' : "#{ConfigDir.path}/#{db_config[:name]}"
      else
        db_config[:name]
      end

      StraightServer.db_connection = Sequel.connect(
        "#{db_config[:adapter]}://"                                                   +
        "#{db_config[:user]}#{(":" if db_config[:user])}"                             +
        "#{db_config[:password]}#{("@" if db_config[:user] || db_config[:password])}" +
        "#{db_config[:host]}#{(":" if db_config[:port])}"                             +
        "#{db_config[:port]}#{("/" if db_config[:host] || db_config[:port])}"         +
        "#{db_name}"
      )

      StraightServer.db_connection.extension :connection_validator
      StraightServer.db_connection.pool.connection_validation_timeout = 600

      StraightServer.db_connection
    end

    def run_migrations
      print "\nPending migrations for the database detected. Migrating..."
      Sequel::Migrator.run(StraightServer.db_connection, MIGRATIONS_ROOT)
      print "done\n\n"
    end

    def migrations_pending?
      !Sequel::Migrator.is_current?(StraightServer.db_connection, MIGRATIONS_ROOT)
    end

    def create_logger
      # TODO: logging to STDOUT by default
      return unless Config.logmaster
      require_relative 'logger'
      Straight.logger = StraightServer.logger = StraightServer::Logger.new(
        log_level:       ::Logger.const_get(Config.logmaster['log_level'].upcase),
        file:            Config.logmaster['file'] && File.absolute_path(Config.logmaster['file'], ConfigDir.path),
        raise_exception: Config.logmaster['raise_exception'],
        name:            Config.logmaster['name'],
        email_config:    Config.logmaster['email_config'],
        logstash_config: Config.logmaster['logstash_config'],
      )
    end

    def initialize_routes
      add_route %r{\A/gateways/.+?/orders(/.+)?\Z} do |env|
        controller = OrdersController.new(env)
        controller.response
      end
      add_route %r{\A/gateways/.+?/last_keychain_id\Z} do |env|
        controller = OrdersController.new(env)
        controller.response
      end
    end

    # Loads addon modules into StraightServer::Server. To be useful,
    # an addon most probably has to implement self.extended(server) callback.
    # That way, it can access the server object and, for example, add routes
    # with StraightServer::Server#add_route.
    #
    # Addon modules can be both rubygems or files under ~/.straight/addons/.
    # If ~/.straight/addons.yml contains a 'path' key for a particular addon, then it means
    # the addon is placed under the ~/.straight/addons/. If not, it is assumed it
    # is already in the LOAD_PATH somehow, with rubygems for example.
    def load_addons
      # load ~/.straight/addons.yml
      addons = YAML.load_file(ConfigDir.path + '/addons.yml')
      addons.each do |name, addon|
        StraightServer.logger.info "Loading #{name} addon"
        if addon['path'] # First, check the ~/.straight/addons dir
          require ConfigDir.path + '/' + addon['path']
        else # then assume it's already loaded using rubygems
          require name
        end
        # extending the current server object with the addon
        extend Kernel.const_get("StraightServer::Addon::#{addon['module']}")
      end if addons
    end

    # Finds orders that have statuses < 2 and starts querying the blockchain
    # for them (unless they are also expired). This is for cases when the server was shut down,
    # but some orders statuses are not resolved.
    def resume_tracking_active_orders!
      StraightServer::Order.where(Sequel.lit("status < 2")).each do |order|

        # Order is expired, but status is < 2! Suspcicious, probably
        # an unclean shutdown of the server. Let's check and update the status manually once.
        if order.time_left_before_expiration < 1
          StraightServer.logger.info "Order #{order.id} seems to be expired, but status remains #{order.status}. Will check for status update manually."
          order.gateway.test_mode = true if order.test_mode
          order.status(reload: true)

          # if we still see no transactions to that address,
          # consider the order truly expired and update the status accordingly
          order.status = StraightServer::Order::STATUSES[:expired] if order.status < 2
          order.save
          StraightServer.logger.info "Order #{order.id} status updated, new status is #{order.status}"

        # Order is NOT expired and status is < 2. Let's keep tracking it.
        else
          StraightServer.logger.info "Resuming tracking of order #{order.id}, current status is #{order.status}, time before expiration: #{order.time_left_before_expiration} seconds."
          StraightServer::Thread.new do
            StraightServer.logger.watch_exceptions do
              order.start_periodic_status_check
            end
          end
        end
      end
    end
    
    def open_ws_connect
      websocket_urls = [StraightServer::Config[:'blockchain_adapters.Insight.websocket_url']].flatten.compact
      unless websocket_urls.empty?
        StraightServer.insight_client = StraightServer::WebsocketInsightClient.new(websocket_urls)
      end
    rescue SocketError
      StraightServer.logger.warn "Please check correctness of Insight.websocket_url in the config file."
    end

    # Loads redis gem and sets up key prefixes for order counters
    # for the current straight environment.
    def setup_redis_connection
      raise "Redis not configured" unless Config.redis
      Config.redis = Config.redis.keys_to_sym
      Config.redis[:prefix] ||= "StraightServer:#{Config.environment}"
      StraightServer.redis_connection = Redis.new(
        host:     Config.redis[:host],
        port:     Config.redis[:port],
        db:       Config.redis[:db],
        password: Config.redis[:password]
      )
    end

  end

end
