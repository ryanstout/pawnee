# Why is this better than Chef/Puppet?

Thats a tough question.  I try to avoid reinventing the wheel, but it seems like the current wheel has some problems.

The main reasons is that Chef and Puppet are both huge solutions to a problem I think could be simplified with a few constraints and better choices.  (chef is over 110k lines of ruby, it doesn't feel like this is a 110k lines of ruby problem)

Also, both seem to have business models that actually harm the product.  For example with Chef, they charge you for a product to help set everything up.  That means that they have incentives to make it difficult to setup.

Here's a few reason why Pawnee is better:

1) Simpler, well written, documented code
2) Leverages existing technology people know (rubygems, thor)
3) Code reuse is built in (all recipes are gems, any part of the gem can be overridden without changing the gem - like rails engines)
4) No need to bootstrap ruby - All actions can be run either locally (with a local ruby) or from a remote server over ssh
5) Clean logging (yea, this is important)
6) Tests - everything is tested using Vagrant


Also, just for good measure, here's a few reasons why its worse:

1) Only supports ubuntu (currently - the plan is to get the kinks worked out on ubuntu first)
2) Fewer recipes (again, currently)


## Problems with Chef/Puppet

[Note: this is my opinion]

1. Little to no testing of recipes (at least for Chef)
2. Complicated recipe upgrading/code reuse patterns
3. You need to run the code locally (should have option to run over ssh)

[chef's providers as an example: http://wiki.opscode.com/display/chef/Resources]
