spree_subscriptions
================

Introduction goes here.

Notes
=======
Subscriptions are created with prices equal to the line item in the order they were created in. Thus if you have a subscribable product of price $5 and the user add 10 to their cart, a subscription of price 10x$5 = $50 will be created. 

It's currently up to you to manage the number of subscribable products that can be added to the cart.

Also, when the subscription manager creates a new order for the payment of
a subscription's dues, it creates a single line item with a price value of the
price stored in the subscription. So, based on the example above, you would
have a new order with a line item worth $50, quantity 1, for the variant
referenced in the subscrition.

Example
=======

Example goes here.


Copyright (c) 2011 [name of extension creator], released under the New BSD License
