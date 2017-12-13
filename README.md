Straight server
===============
> A stand-alone Bitcoin payment gateway server.
> Receives bitcoin payments directly into your wallet, holds no private keys
>
> It is used as a backend for the hosted service https://gear.mycelium.com
> Instead of installing the gateway yourself, you can just use
> Mycelium Gear and accept payments through it. Of course, straight
> into your wallet again - no private key required.

> Website: https://gear.mycelium.com

If you'd like to accept Bitcoin payments on your website automatically, but you're not
fond of services like Coinbase or Bitpay, which hold your bitcoins for you and require a ton
of AML/KYC info, you came to the right place.

Straight server is a software you install on your machine, which you can then talk to
via a RESTful API to create orders and generate payment addresses. Straight server will
issue callback requests to the specified URLs when the bitcoins arrive and store all the information
about the order in a DB.

While it is written in Ruby, I made special effort so that it would be easy to install and configure.
You can use Straight server with any application and website. You can even run your own payment
gateway which serves many online stores.

Straight uses BIP32 pubkeys so that you and only you control your private keys.
If you're not sure what a BIP32 address and HD wallets are, read this article:
http://bitcoinmagazine.com/8396/deterministic-wallets-advantages-flaw/

You might also be interested in a stateless [Straight](https://github.com/MyceliumGear/straight) library that is the base for Straight server.

Installation
------------
I currently only tested it on Unix machines.

1. Install RVM, Ruby 2.1 (see [RVM guide](http://rvm.io/rvm/install)) and Redis.

2. run `gem install straight-server`

3. start the server by running `straight-server`. This will generate a` ~/.straight` dir and put a `config.yml`
file in there, then shut down. You have to edit the file first to be able to run the server again.

4. In `config.yml`, under the `gateways/default` section, insert your BIP32 pubkey and a callback URL.
Everything may be left as is for now. To generate a BIP32 private/public keys, you can use one of the
wallets that support BIP32 (currently it's bitWallet for iOS or Electrum) or go to http://bip32.org

5. Run the server again with `straight-server -p 9696`

If `straight-server` after the start reports that there is no test key, you should:

In test mode generate a test key and add it to `config.yml`
    
    test_pubkey: tpub.....
    
Or, if you are not using test mode, set: 
    
    test_mode: false
    
It is recommended to run `straight-server` not as `gem`, but locally.

    bundle exec bin/straight-server

In `Gemfile` add a `path:` to use `gem` 'straight' locally too:

    gem 'straight', path: '/home/work/straight'

Usage
-----
**bugfix**
please comment (put # before first character) or remove the following lines from lib/straight/faraday_monkeypatch.rb like so:
```
#Faraday::SSLOptions = Faraday::Options.new(*(Faraday::SSLOptions.members | [:verify_callback])) do
#  def verify?
#    verify != false
#  end
#  def disable?
#    !verify?
#  end
#end
```

When the server is running, you can access it via http and use its RESTful API.
Below we assume it runs on localhost on port 9696.

**Creating a new order:**

    # creates a new order for 1 satoshi
    POST /gateways/1/orders?amount=1

the result of this request will be the following json:

    {"status":0,"amount":1,"address":"1NZov2nm6gRCGW6r4q1qHtxXurrWNpPr1q","tid":null,"id":1, keychain_id: 1, last_keychain_id: 1 }

Now you can obviously use that output to provide your user with the address and the expected
amount to be sent there. At this point, the server starts automatically tracking the order address
in a separate thread, so that when the money arrive, a callback will be issued to the url provided
in the `~/.straight/config.yml` file for the current gateway. This callback request will contain order info too.

Here's an example of a callback url request that could be made by Straight server when order status changes:

    GET http://mystore.com/payment-callback?order_id=234&amount=1&amount_in_btc=0.00000001&amoint_paid_in_btc=0.00000001&status=2&address=1NZov2nm6gRCGW6r4q1qHtxXurrWNpPr1q&tid=tid1&callback_data=some+random+data&keychain_id=1&last_keychain_id=1

As you may have noticed, there's a parameter called `callback_data`. It is a way for you to pass info back
to your app. It will have the same value as the `callback_data` parameter you passed to the create order request:

    POST /gateways/1/orders?amount=1&callback_data=some+random+data

You can specify amount in other currencies, as well as various BTC denominations.
It will be converted using the current exchange rate (see [Straight::ExchangeAdapter](https://github.com/MyceliumGear/straight/blob/master/lib/straight/exchange_rate_adapter.rb)) into satoshis:

    # creates a new order for 1 USD
    POST /gateways/1/orders?amount=1&currency=USD

    # creates an order for 0.00000001 BTC or 1 satoshi
    POST /gateways/1/orders?amount=1&btc_denomination=btc


**Checking the order manually**
You can check the status of the order manually with the following request:

    GET /gateways/1/orders/:id

where `:id` can either be order `id` (CAUTION: order `id` is NOT the same as `keychain_id`) or
`payment_id` - both are returned in the json data when the order
is created (see above). The request above may return something like:

    {"status":2,"amount":1,"address":"1NZov2nm6gRCGW6r4q1qHtxXurrWNpPr1q","tid":"f0f9205e41bf1b79cb7634912e86bb840cedf8b1d108bd2faae1651ca79a5838","id":1,"amount_in_btc": 0.00000001,"amount_paid_in_btc": 0.00000001,"keychain_id": 1,"last_keychain_id": 1 }

**Subscribing to the order using websockets**:
You can also subscribe to the order status changes using websockets at:

    /gateways/1/orders/1/websocket

It will send a message to the client upon the status change and close connection afterwards.

**Order expiration**
means that after a certain time has passed, it is no longer possible to pay for it. Each order holds
its creation time in `#created_at` field. In turn, each order's gateway has a field called
`#orders_expiration_period` (you can set it as an option in config file for each particular gateway or in the DB,
depending on what approach to storing gateways you use). After this time has passed, straight-server stops
checking whether new transactions appear on the order's bitcoin address and also changes order's status to 5 (expired).

**Get last keychain id**
You can get last keychain id for gateway with the following request:

    GET /gateway/1/last_keychain_id

The request above return something like:

    {"gateway_id": 1, "last_keychain_id": "11"}

Implications of restarting the server
-------------------------------------

If you shut the server down and then start it again, all unresolved orders (status < 2 and non-expired)
are automatically picked up and the server starts checking on them again until they expire. Please note
that you'd need to make sure your client side reconnects to the order's websocket again. This is because
on server shutdown, all websocket connections are closed, therefore, there's no way to automatically restore them.
It is thus client's responsibility to check when websocket is closed, then periodically try to connect to it again.

Client Example
--------------
I've implemented a small client example app written purely in Dart. It creates new orders,
tracks changes via websockets and displays status info upon status change. To see how it works,
download Dartium browser and navigate it to the `http://localhost:9696` while running the
Straight server in development mode (nothing special has to be done for that).

The code for this client app example can be found in [examples/client](https://github.com/MyceliumGear/straight-server/tree/master/examples/client).

Using many different gateways
------------------------------
When you have many online stores, you'd want to create a separate gateway for each one of them.
They would all be running within one Straight server.

The standard way to do this is to use `~/.straight/config.yml` file. Under the `gateways` section,
simply add a new gateway (come up with a nice name for it!) and set all the options you see were
used for the default one. Change them as you wish. Restart the server.

To create an order for the new gateway, simply send this request:

    POST /gateways/2/orders?amount=1&currency=USD

Notice that the gateway id has changed to 2. Gateway ids are assigned according to the order in
which they follow in the config file.

Gateways from DB
----------------
When you have too many gateways, it is unwise to keep them in the config file. In that case,
you can store gateway settings in the DB. To do that, change `~/.straight/config.yml` setting
'gateways_source: config` to `gateways_source: db`.

Then you should be able to use `straight-console` to manually create gateways to the DB. To do
that, you'd have to consult [Sequel documentation](http://sequel.jeremyevans.net/) because currently
there is no standard way to manage gateways through a web interface. In the future, it will be added.
In general, it shouldn't be difficult, and may look like this:

    $ straight-console
    
    > gateway = Gateway.new
    > gateway.pubkey                 = 'xpub1234'
    > gateway.confirmations_required = 0
    > gateway.order_class            = 'StraightServer::Order'
    > gateway.callback_url           = 'http://myapp.com/payment_callback'
    > gateway.save
    > exit

One important thing to remember when using DB based Gateways is that when you want to issue a request to
create a new order, you must use `Gateway#hashed_id` instead of `#id`. This is because otherwise it becomes very easy
for a third-party to just go through gateways consecutively.

For example, suppose you have a DB based gateway with id 23. The incorrect request to create a new order would be

    POST /gateways/23/orders?amount=1 # THIS IS WRONG!

We first need to find that gateway's hashed id:

    $ straight-console
    
    > gateway = Gateway[23]
    > gateway.hashed_id # => '587bb9b74e37f526eac47081ad61998726673760c77415d52a95bf38fba9cbe9'

And then we can make a correct request:

    POST /gateways/587bb9b74e37f526eac47081ad61998726673760c77415d52a95bf38fba9cbe9/orders?amount=1

Using signatures
----------------
If you are running straight-server on a machine separate from your online stores, you
HAVE to make sure that when somebody accesses your RESTful API it is those stores only,
and not somebody else. For that purpose, you're gonna need signatures.

Go to your `~/.straight/config.yml` directory and set two options for each of your gateways:

    secret: 'a long string of random chars'
    check_signature: true

This will force gateways to check signatures when you try to create a new order.
A signature is a `X-Signature` header with a string of about 88 chars: 

    Base64StrictEncode(
      HMAC-SHA512(
        REQUEST_METHOD + REQUEST_URI + SHA512(X-Nonce + REQUEST_BODY),
        GATEWAY_SECRET
      )
    )

Where

* `REQUEST_METHOD`: `GET`, `POST`, etc.
* `REQUEST_URI`: `/full/path/with?arguments&and#fragment`
* `REQUEST_BODY`: final string with JSON or blank string
* `X-Nonce`: header with an integer which must be incremented with each request (protects from replay attack), for example `(Time.now.to_f * 1000).to_i`
* `SHA512`: [binary SHA-2, 512 bits](https://en.wikipedia.org/wiki/SHA-2)
* `HMAC-SHA512`: [binary HMAC with SHA512](https://en.wikipedia.org/wiki/Hash-based_message_authentication_code)
* `GATEWAY_SECRET`: key for HMAC
* `Base64StrictEncode`: [Base64 encoding according to RFC 4648](https://en.wikipedia.org/wiki/Base64#RFC_4648)

For Ruby users signing is already implemented in `straight-server-kit` gem. 

Straight server will also sign the callback url request. However, it will use blank X-Nonce.

    GET http://mystore.com/payment-callback?order_id=1&amount=10&amount_in_btc=0.0000001&amount_paid_in_btc=0.&status=1&address=address_1&tid=tid1&keychain_id=1&last_keychain_id=1&callback_data=so%3Fme+ran%26dom+data
    X-Signature: S2P8A16+RPaegTzJnb0Eg91csb1SExjdnvadABmQvfoIry4POBp6WbA6UOSqXojzRevyC8Ya/5QrQTnNxIb4og==

It is now up to your application to calculate that signature and compare it.
If it doesn't match, do not trust data, instead log it for further investigation and return 200 in order to prevent retries.  

What is keychain_id and why do we need it?
------------------------------------------

`keychain_id` is used to derive the next address from your BIP32 pubkey.
If you try to create orders with the same `keychain_id` they will also have the same
address, which is, as you can imagine, not a very good idea. However it is allowed and there's
a good reason for that.

Wallets that support BIP32 pubkeys will only do a forward address lookup for a limited number of
addreses. For example, if you have 20 expired, unpaid orders and someone sends you money to the address
of the 21-st order, your wallet may not see that. Thus, it is important to ensure that there are
no more than N expired orders in a row. The respective setting in the config file is called
`reuse_address_orders_threshold` and the default value is 20.

If you have 20 orders in a row and try to create another one, straight-server will see that and will
automatically reuse the `keychain_id` (and consequently, the address too) of the 20-th order. It will
also set the 21-st order's `reused` field to the value of `1`.

Querying the blockchain
-----------------------
Straight currently uses third-party services, such as Blokchain.info and Helloblock.io to track
addresses and fetch transaction info. This means, you don't need to install bitcoind and store
the whole blockchain on your server. If one service is down, it will automatically switch to another one.
I will be adding more adapters in the future. It will also be possible to implement a cross check where if
one service is lying about a transaction, I can check with another. In the future, I will add bitcoind support
too for those who do not trust third-party services.

To sum it up, there is nothing in the architecture of this software that says you should rely on third party services
to query the blockchain.

Counting orders
---------------
For easy statistics and reports, it is desirable to know how many orders of each particular status each gateway has.
For that reason optional order counters are implemented. To enable order counters, make sure the following options are set:

    count_orders: true       # enable order counting feature

After restarting the server, you can use `Gateway#order_counters` method which will
return a hash of all the counters. Here's an example output:

    { new: 132, unconfirmed: 0, paid: 34, underpaid: 1, overpaid: 2, expired: 55, canceled: 10 }

The default behaviour is to cache the output, so if you want fresh values, use `reload: true`
option on this method:

    Gateway#order_counters(reload: true)

Throttling
----------

If Gateway does not require signature check (e.g. it's a public widget), you may wish to limit orders creation.
This may help to mitigate potential DoS attacks.
In order to enable throttler, edit your config file and make sure the following options are set:

    throttle:
      requests_limit: 21
      period: 60
      ip_ban_duration: 300

This will allow maximum 21 new orders per 60 seconds per gateway to be created.
`ip_ban_duration` is optional and prevents users from the banned IP (think of NAT) to create orders via any gateway for 300 seconds.
When using this option, make sure that `HTTP_X_FORWARDED_FOR` header contains end user's IP. For example, in nginx config:

    proxy_set_header X-Forwarded-For $remote_addr;

Also, check out [ngx_http_realip_module](http://nginx.org/en/docs/http/ngx_http_realip_module.html).

BIP0070 payment protocol
------------------------

Straight server provides the ability to implement the 
[payment protocol](https://github.com/bitcoin/bips/blob/master/bip-0070.mediawiki).
We recommend using CA certificates to sign payment requests. To do this, set following options in your 
config file: 

    ssl_certificate_path: '/path/to/ssl_certificate'
    private_key_path:     '/path/to/private_key'

To send a payment request file to wallet, simply use this request:

    GET /gateways/1/orders/2/invoice 

Running in production
---------------------
Running in production usually assumes running server as daemon with a pid. Straight server
uses [Goliath](https://github.com/postrank-labs/goliath) so you can look up various options there.
However, my recommendation is the following:

    straight-server -e production -p 9696 --daemonize --pid ~/.straight/straight.pid

Note that goliath server log file settings do not apply here. Straight has its own logging
system and the file is usually `~/.straight/straight.log`. You can set various loggin options
in `~/.straight/config.yml`. For production, you may want to set log level to WARN and also
turn on email notifications, so that when a FATAL errors occurs, an email is sent to you address
(emailing would most likely require *sendmail* to be installed).

I would also recommend you to use something like *monit* daemon to monitor a *straight-server* process.

Running in different environments
---------------------------------
Additionally, there is a `--config-dir` (short version is `-c`) option that allows you to set the
config directory for the server. It becomes quite convenient if you decide to run, for example, both
production and staging instances on one machine. I decided against having config file sections for each environment
as this would be more complicated and quite unnatural. Apart from different config files, one might argue you can have
a different set of addons and different versions of them in the `~/.straight/addons` dir. So it's better to keep them separate.

If you think of wrong examples out there, consider Rails: why would I want to have a database.yml file with both
development and production sections if I know for sure I'm only running this instance in production env?

So, with straight, you can simply create a separate config dir for each instance. For example, if I want to run
both production and staging on my server, I'd do this:

1. Create `~/.straight/production` and `~/.straight/staging` dirs
2. Run two instances like this:

       straight-server --config-dir=~/.straight/production 
       straight-server --config-dir=~/.straight/staging

It's worth saying that currently, there is no default settings for production, staging or development.
It is you who defines what a production or a staging environment is, by changing the config file. Those words
are only used as examples. You may call your environment whatever you like.

However, environment name is currently used as a prefix for gateway order counters Redis entries
(see the respective README section). You can set the current environment name using a config file option, for example:

    environment: development

Addons
------
WARNING: this is currently work in progress. The final specification of how addons should be added
and how they interact with the server may change.

Currently there is only one use case for addons and thus only one way in which addons can interact with the server itself:
adding controllers and routes for them. Now let's look at how we should do that:

1. All addons are placed under `~/.straight/addons/` (of course, it is wise to use symlinks).

2. `~/.straight/addons.yml` file lists addons and tells straight-server what are the names of the files to be loaded.
The format of the file is the following:


    my_addon                             # <- name doesn't affect anything, just shows up in the log file
      path: addons/my_addon/lib/my_addon # <- This is unnecessary if addon is already in the LOAD_PATH
      module: MyAddon                    # <- actual module should be a submodule of StraightServer::Addon

3. If addon has dependencies, they can be listed in `~/.straight/AddonsGemfile` and will be installed along with `straight-server` dependencies.


    eval_gemfile '/home/app/.straight/addons/my_addon/Gemfile'

4. In `./straight/addons/my_addon/lib/` we will place two files, `my_addon.rb` and 'my_controller.rb'. Below is their contents:


    # my_addon.rb
    
    require_relative 'my_controller'

    module StraightServer
      module Addon
        module MyAddon
          
          def self.extended(obj)
            obj.add_route /\A\/my_controller/.*\Z/ do |env|
              controller = MyController.new(env)
              controller.show
            end
          end

        end
      end
    end

As you can guess, `#add_route` is a straight-server's special method for defining routes, very similar to Rails.
The piece of code above will force all requests where urls are starting with `/my_controller` to be handled by
`MyController#show`:


    # my_controller.rb

    module StraightServer
      class MyController
        def show
          [200, {}, "Hello world! This is MyController speaking!"]
        end
      end
    end

And this in turn will render us the text "Hello world! This is MyController speaking!".
Here, we've just created our first addon.


Requirements
------------
Ruby 2.1 or later.

Donations
---------
To go on with this project and make it truly awesome, I need more time. I can only buy free time with money, so any donation is highly appreciated. Please send bitcoins over to **1D3PknG4Lw1gFuJ9SYenA7pboF9gtXtdcD**

Credits
-------
Author: [Roman Snitko](http://romansnitko.com)

Licence: MIT (see the LICENCE file)
