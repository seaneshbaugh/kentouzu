# Kentouzu

Kentouzu is a Ruby gem that lets you create draft versions of your ActiveRecord models upon saving. If you're developing a publishing approval queue then Kentouzu just might be what you need. It's heavily based off the wonderful [paper_trail](https://github.com/airblade/paper_trail) gem. In fact, much of the code for this gem was pretty much lifted line for line from paper_trail (because it works beautifully). You should definitely check out paper_trail and its source. It's a nice clean example of a gem that hooks into Rails.

## Rails Version

This gem has only been tested on Rails 3.2. There is no reason that I am aware of that would prevent it from working on all versions of Rails 3 (and Rails 4 when it is released). As Kentouzu is based on the Rails 3 branch of paper_trail it's very unlikely that it will work with Rails 2.3.

## Installation

Add the gem to your project's Gemfile:

    gem 'kentouzu'

Generate a migration for the drafts table:

    $ rails g kentouzu:install

Run the migration:

    $ rake db:migrate

Add `has_drafts` to the models you want to have drafts on.

## API Summary

When you call `has_drafts` in your model you get the following methods:

```ruby
class Widget < ActiveRecord::Base
  has_drafts  # you can pass various options here
end

# Returns this widget's drafts.
# You can customize the name of this association.
widget.drafts

# Return the draft this widget was reified from, or nil if it is live.
# You can customize the name of this method.
widget.draft

# Returns all "new" drafts for the model. These drafts were not created from existing instances of the model or from previous drafts.
# You can customize the name of this method.
Widget.new_drafts
```

The `Draft` class has the following methods:

```ruby
# Returns all drafts created by the `create` event.
Draft.creates

# Returns all drafts created by the `update` event.
Draft.updates
```

And a `Draft` instance has these methods:

```ruby
# Return the object held by the draft.
draft.reify(options = {})

# Reify the draft and then destroy it.
widget.approve

# Destroy the draft.
draft.reject
```

More on this later!

## Basic Usage

More on this later!

## Contributing

If you feel like you can add something useful to Kentouzu then don't hesitate to contribute! To make sure your fix/feature has a high chance of being included, please do the following:

1. Fork the repo.

2. Run the tests. I will only take pull requests with passing tests, and it's great to know that you have a clean slate: `bundle && rake`

3. Add a test for your change. Only adding tests for existing code, refactoring, and documentation changes require no new tests. If you are adding functionality or fixing a bug, you need a test!

4. Make the test pass.

5. Push to your fork and submit a pull request.

I can't guarantee that I will accept the change, but if I don't I will be sure to let you know why!

Some things that will increase the chance that your pull request is accepted, taken straight from the Ruby on Rails guide:

* Use Rails idioms and helpers
* Include tests that fail without your code, and pass with it
* Update the documentation, guides, or whatever is affected by your contribution

Yes, I am well aware of the irony of asking for tests when there are effectively none right now. This gem is a work in progress.

## A Note of Warning

This gem overwrites the ActiveRecord save method. In isolation this is usually harmless. But, in combination with other gems that do the same, unpredictable behavior may result. As always, use caution, and be aware of what this gem and any others you use actually do before including it in an important project.

## Kentouzu?
"検討図" (けんとうず, kentouzu) means "draft" or "plan" in Japanese. Since "drafts" was already taken as a gem name, an appropriate Japanese word seemed like a good idea.
