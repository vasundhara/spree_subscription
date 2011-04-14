spree_subscriptions
===============================================================================
Provides subscribable functionality for your products/variants.

Installation
===============================================================================
    gem 'spree_subscriptions'
    bundle install

    #run your db migrations
    #visit the spree admin for products and create something subscribable!


Migrating From Authorize.net ARB Subscriptions
===============================================================================
If you are currently using authorize.net ARB subscriptions for your users, you
can migrate those users to your own self hosted solution by providing a field in the
subscription table and then setting up some config values in an initalizer like
so:

    SpreeSubscriptions::Config.migrate_from_authorize_net_subscriptions = true
    SpreeSubscriptions::Config.authorizenet_subscription_id_field       = 'authorizenet_subscription_id' 
   
**You must provide your own migration for the reference to the authorize.net
arb subscription id value. If that field doesn't exist in your subscription
model you will get errors.** Something like the following could work to build
the field:

    rails generate migration add_arb_reference_to_subscriptions authorizenet_subscription_id:integer

You will still need to provide your own migration to move your data to the
subscription model.

Once you've migrated then anytime a subscription is updated or canceled, if it
has a reference to Authorize.net then it will be cancelled in authorize.net and
(if the data is an update) updated to use local recurring billing via the
subscription manager.


Notes
===============================================================================
Subscriptions are created with prices equal to the line item in the order they were created in. Thus if you have a subscribable product of price $5 and the user add 10 to their cart, a subscription of price 10x$5 = $50 will be created. 

It's currently up to you to manage the number of subscribable products that can be added to the cart.

Also, when the subscription manager creates a new order for the payment of
a subscription's dues, it creates a single line item with a price value of the
price stored in the subscription. So, based on the example above, you would
have a new order with a line item worth $50, quantity 1, for the variant
referenced in the subscrition.

Example
===============================================================================

Example goes here.


Copyright (c) 2011 [name of extension creator], released under the New BSD License
