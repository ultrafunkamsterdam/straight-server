# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: straight-server 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "straight-server"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Roman Snitko"]
  s.date = "2015-09-08"
  s.description = "Accepts orders via http, returns payment info via http or streams updates via websockets, stores orders in a DB"
  s.email = "roman.snitko@gmail.com"
  s.executables = ["straight-console", "straight-server", "straight-server-benchmark"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".dockerignore",
    ".document",
    ".rspec",
    ".travis.yml",
    "Dockerfile",
    "Gemfile",
    "Gemfile.lock",
    "Gemfile.travis",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "benchmark/addons.yml",
    "benchmark/config.yml",
    "benchmark/default_last_keychain_id",
    "benchmark/server_secret",
    "bin/straight-console",
    "bin/straight-server",
    "bin/straight-server-benchmark",
    "db/migrations/001_create_orders.rb",
    "db/migrations/002_create_gateways.rb",
    "db/migrations/003_add_payment_id_to_orders.rb",
    "db/migrations/004_add_description_to_orders.rb",
    "db/migrations/005_add_orders_expiration_period_to_gateways.rb",
    "db/migrations/006_add_check_order_status_in_db_first_to_gateways.rb",
    "db/migrations/007_add_active_switcher_to_gateways.rb",
    "db/migrations/008_add_order_counters_to_gateways.rb",
    "db/migrations/009_add_hashed_id_to_gateways.rb",
    "db/migrations/010_add_address_reusability_orders.rb",
    "db/migrations/011_add_callback_data_to_orders.rb",
    "db/migrations/012_add_address_provider.rb",
    "db/migrations/013_add_address_derivation_scheme.rb",
    "db/migrations/014_pubkey_null_address_provider_not_null.rb",
    "db/migrations/015_add_amount_paid_to_orders.rb",
    "db/migrations/016_add_new_params_to_orders.rb",
    "db/migrations/017_add_test_mode_to_gateways.rb",
    "db/migrations/018_add_test_keychain_id_to_gateways.rb",
    "db/migrations/019_add_test_pubkey_to_gateways.rb",
    "db/migrations/020_add_test_mode_to_orders.rb",
    "db/migrations/021_add_fields_for_after_payment_redirect.rb",
    "db/migrations/022_add_merchant_url.rb",
    "db/schema.rb",
    "examples/client/client.dart",
    "examples/client/client.html",
    "examples/client/client.js",
    "lib/straight-server.rb",
    "lib/straight-server/config.rb",
    "lib/straight-server/errors.rb",
    "lib/straight-server/gateway.rb",
    "lib/straight-server/initializer.rb",
    "lib/straight-server/logger.rb",
    "lib/straight-server/order.rb",
    "lib/straight-server/orders_controller.rb",
    "lib/straight-server/random_string.rb",
    "lib/straight-server/server.rb",
    "lib/straight-server/signature_validator.rb",
    "lib/straight-server/thread.rb",
    "lib/straight-server/throttler.rb",
    "lib/straight-server/utils/hash_string_to_sym_keys.rb",
    "lib/straight-server/websocket_insight_client.rb",
    "lib/tasks/db.rake",
    "spec/.straight/config.yml",
    "spec/.straight/default_test_last_keychain_id",
    "spec/.straight/server_secret",
    "spec/factories.rb",
    "spec/fixtures/addons.yml",
    "spec/fixtures/test_addon.rb",
    "spec/lib/gateway_spec.rb",
    "spec/lib/initializer_spec.rb",
    "spec/lib/order_spec.rb",
    "spec/lib/orders_controller_spec.rb",
    "spec/lib/signature_validator_spec.rb",
    "spec/lib/thread_spec.rb",
    "spec/lib/throttle_spec.rb",
    "spec/lib/utils/hash_string_to_sym_keys.rb",
    "spec/lib/websocket_insight_client_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/custom_matchers.rb",
    "spec/support/logger_context.rb",
    "straight-server.gemspec",
    "templates/addons.yml",
    "templates/config.yml"
  ]
  s.homepage = "http://github.com/snitko/straight-server"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5"
  s.summary = "A Bitcoin payment gateway server: a state server for the stateless Straight library"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<straight>, ["= 1.0.0"])
      s.add_runtime_dependency(%q<satoshi-unit>, ["= 0.1.8"])
      s.add_runtime_dependency(%q<goliath>, [">= 0"])
      s.add_runtime_dependency(%q<faye-websocket>, [">= 0"])
      s.add_runtime_dependency(%q<socket.io-client-simple>, [">= 0"])
      s.add_runtime_dependency(%q<sequel>, [">= 0"])
      s.add_runtime_dependency(%q<logmaster>, ["~> 0.2.0"])
      s.add_runtime_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_runtime_dependency(%q<httparty>, [">= 0"])
      s.add_runtime_dependency(%q<redis>, [">= 0"])
      s.add_runtime_dependency(%q<btcruby>, ["= 1.1.1"])
      s.add_runtime_dependency(%q<ruby-protocol-buffers>, [">= 0"])
      s.add_development_dependency(%q<byebug>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_development_dependency(%q<github_api>, ["= 0.11.3"])
    else
      s.add_dependency(%q<straight>, ["= 1.0.0"])
      s.add_dependency(%q<satoshi-unit>, ["= 0.1.8"])
      s.add_dependency(%q<goliath>, [">= 0"])
      s.add_dependency(%q<faye-websocket>, [">= 0"])
      s.add_dependency(%q<socket.io-client-simple>, [">= 0"])
      s.add_dependency(%q<sequel>, [">= 0"])
      s.add_dependency(%q<logmaster>, ["~> 0.2.0"])
      s.add_dependency(%q<ruby-hmac>, [">= 0"])
      s.add_dependency(%q<httparty>, [">= 0"])
      s.add_dependency(%q<redis>, [">= 0"])
      s.add_dependency(%q<btcruby>, ["= 1.1.1"])
      s.add_dependency(%q<ruby-protocol-buffers>, [">= 0"])
      s.add_dependency(%q<byebug>, [">= 0"])
      s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
      s.add_dependency(%q<github_api>, ["= 0.11.3"])
    end
  else
    s.add_dependency(%q<straight>, ["= 1.0.0"])
    s.add_dependency(%q<satoshi-unit>, ["= 0.1.8"])
    s.add_dependency(%q<goliath>, [">= 0"])
    s.add_dependency(%q<faye-websocket>, [">= 0"])
    s.add_dependency(%q<socket.io-client-simple>, [">= 0"])
    s.add_dependency(%q<sequel>, [">= 0"])
    s.add_dependency(%q<logmaster>, ["~> 0.2.0"])
    s.add_dependency(%q<ruby-hmac>, [">= 0"])
    s.add_dependency(%q<httparty>, [">= 0"])
    s.add_dependency(%q<redis>, [">= 0"])
    s.add_dependency(%q<btcruby>, ["= 1.1.1"])
    s.add_dependency(%q<ruby-protocol-buffers>, [">= 0"])
    s.add_dependency(%q<byebug>, [">= 0"])
    s.add_dependency(%q<jeweler>, ["~> 2.0.1"])
    s.add_dependency(%q<github_api>, ["= 0.11.3"])
  end
end

