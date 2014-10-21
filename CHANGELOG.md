## v0.2.0

* Breaking changes to the way objects are serialized and deserialized.
* `has_many` associations are now serialized along with the object.
* Deprecated `drafts_on` and `drafts_off` in favor of `drafts_on!` and `drafts_off!`.
* Added `Kentouzu.enabled_for_model` and `Kentouzu.enabled_for_model?`.
* Added `Kentouzu.active_record_protected_attributes?` to enable handling of attr_accessible.
* Attempt to load `protected_attributes` gem if it's available.
* Added `Draft.with_source_keys`.
* Deprecated `Draft#approve` and `Draft#reject`.
* Added override for `save!`.

## v0.1.2

* Added callbacks for `before_draft_save`, `after_draft_save`, and `around_draft_save`.
* Fixed a bug where invalid attributes were merged from controller options when saving a draft.

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
