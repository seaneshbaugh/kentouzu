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
