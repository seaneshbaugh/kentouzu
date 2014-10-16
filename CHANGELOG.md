## v0.1.1

* Fixed a bug in the `has_many :drafts` association for Rails 4. Since it uses a lambda for the order scope `self` is the class `has_drafts` was called in.

## v0.1.0

* Rails 4 compatibility.

## v0.0.13

* Fixed 'all_with_reified_drafts` so that the most recent existing draft is pulled, overriding older drafts.

## v0.0.12

* Fixed `all_with_reified_drafts` so that it works with STI.

## v0.0.11

* Save now merges data from Kentouzu.controller_info.

## v0.0.10

* Fixed `all_with_reified_drafts` so that it actually takes a block.

## v0.0.9

* Added `all_with_reified_drafts` method.
* Changed `()` to `call` for clarity in overridden `save` method.
* Tidied up some formatting.

## v0.0.8

* Fixed bug that occurs when reifying object with STI when type column is blank.
* Started adding a dummy test app.

## v0.0.7

* Updated dependencies to allow for Rails 4.

## v0.0.6

* Removed debug output from new save method.

## v0.0.5

* Removed debug output from new save method.

## v0.0.4

* `save` now uses `base_class` instead of just `class`.

## v0.0.3

* Fixed the require in reify. `self.item_type.underscore` instead of `self.item_type.downcase`.
* Removed debug output from without_drafts.
* Added with_drafts.

## v0.0.2

* Fixed bug in reify.

## v0.0.1

* Initial release.
