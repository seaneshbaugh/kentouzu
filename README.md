# Kentouzu

Kentouzu is a Ruby gem that lets you create draft versions of your ActiveRecord models upon saving. If you're developing a publishing approval queue then Kentouzu just might be what you need. It's heavily based off the wonderful [paper_trail](https://github.com/airblade/paper_trail) gem. In fact, much of the code for this gem was pretty much lifted line for line from paper_trail (because it works beautifully). You should definitely check out paper_trail and it's source. It's a nice clean example of a gem that hooks into Rails.

## Rails Version

This gem has only been tested on Rails 3.2. There is no reason that I am aware of that would prevent it from working on all versions of Rails 3 (and Rails 4 when it is released). As Kentouzu is based on the Rails 3 branch of paper_trail it's very unlikely that it will work with Rails 2.3.

## Installation

Add the gem to your project's Gemfile:

    `gem 'kentouzu'`

Generate a migration for the drafts table:

    `rails g kentouzu:install`

Run the migration:

    `rake db:migrate`

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
```

## Basic Usage

More on this later!

## Contributing

If you feel like you can add something useful to Kentouzu then don't hesitate to send a pull request.

## A Note of Warning

This gem overwrites the ActiveRecord save method. In isolation this is usually harmless. But, in combination with other gems that do the same, unpredictable behavior may result. As always, use caution, and be aware of what this gem and any others you use actually do before including it in an important project.

## Kentouzu?
"検討図" (けんとうず, kentouzu) means "draft" or "plan" in Japanese. Since "drafts" was already taken as a gem name, an appropriate Japanese word seemed like a good idea.
