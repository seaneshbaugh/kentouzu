require 'singleton'
require 'yaml'

require 'kentouzu/config'
require 'kentouzu/controller'
require 'kentouzu/has_drafts'

module Kentouzu
  # Switches Kentouzu on or off globally.
  def self.enabled=(value)
    Kentouzu.config.enabled = value
  end

  # Returns `true` if Kentouzu is enabled globally, `false` otherwise.
  # Kentouzu is enabled by default.
  def self.enabled?
    !!Kentouzu.config.enabled
  end

  # Switches Kentouzu on or off for the current request.
  def self.enabled_for_controller=(value)
    drafts_store[:request_enabled_for_controller] = value
  end

  # Returns `true` if Kentouzu is enabled for the current request, `false` otherwise.
  def self.enabled_for_controller?
    !!drafts_store[:request_enabled_for_controller]
  end

  # Switches Kentouzu on or off for the model for the current request.
  def self.enabled_for_model(model, value)
    drafts_store[:"enabled_for_#{model}"] = value
  end

  # Returns `true` if Kentouzu is enabled for the model for the current request, `false` otherwise.
  def self.enabled_for_model?(model)
    !!drafts_store.fetch(:"enabled_for_#{model}", true)
  end

  # Set the field which records when a draft was created.
  def self.timestamp_field=(field_name)
    Kentouzu.config.timestamp_field = field_name
  end

  # Returns the field which records when a draft was created.
  def self.timestamp_field
    Kentouzu.config.timestamp_field
  end

  # Sets who is responsible for creating the draft.
  # Inside of a controller this will automatically be set to `current_user`.
  # Outside of a controller it will need to be set manually.
  def self.source=(value)
    drafts_store[:source] = value
  end

  # Returns who is responsible for creating the draft.
  def self.source
    drafts_store[:source]
  end

  # Sets any information from the controller that you want Kentouzu to store.
  def self.controller_info=(value)
    drafts_store[:controller_info] =  value
  end

  # Returns any information from the controller that you want Kentouzu to store.
  def self.controller_info
    drafts_store[:controller_info]
  end

  # Returns `true` if ActiveRecord requires mass assigned attributes to be whitelisted via `attr_accessible`, `false` otherwise.
  def self.active_record_protected_attributes?
    @active_record_protected_attributes ||= ActiveRecord::VERSION::MAJOR < 4 || !!defined?(ProtectedAttributes)
  end

  private

  # Thread-safe hash to hold Kentouzu's data.
  # Initialized to enable Kentouzu for all controllers.
  def self.drafts_store
    Thread.current[:draft] ||= { :request_enabled_for_controller => true }
  end

  # Returns Kentouzu's configuration object.
  def self.config
    @@config ||= Kentouzu::Config.instance
  end
end

require 'kentouzu/draft'

# Ensure `protected_attributes` gem gets required if it is available before the `Draft` class is loaded.
unless Kentouzu.active_record_protected_attributes?
  Kentouzu.send(:remove_instance_variable, :@active_record_protected_attributes)

  begin
    require 'protected_attributes'
  rescue LoadError
    # Don't blow up if the `protected_attributes` gem is not available.
    nil
  end
end

# Include `Kentouzu::Model` into `ActiveRecord::Base`
ActiveSupport.on_load(:active_record) do
  include Kentouzu::Model
end

# Include `Kentouzu::Controller` into `ActionController::Base`
ActiveSupport.on_load(:action_controller) do
  include Kentouzu::Controller
end
