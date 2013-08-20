require 'singleton'
require 'yaml'

require 'kentouzu/config'
require 'kentouzu/controller'
require 'kentouzu/has_drafts'
require 'kentouzu/draft'

module Kentouzu
  def self.enabled=(value)
    Kentouzu.config.enabled = value
  end

  def self.enabled?
    !!Kentouzu.config.enabled
  end

  def self.enabled_for_controller=(value)
    drafts_store[:request_enabled_for_controller] = value
  end

  def self.enabled_for_controller?
    !!drafts_store[:request_enabled_for_controller]
  end

  def self.timestamp_field=(field_name)
    Kentouzu.config.timestamp_field = field_name
  end

  def self.timestamp_field
    Kentouzu.config.timestamp_field
  end

  def self.source=(value)
    drafts_store[:source] = value
  end

  def self.source
    drafts_store[:source]
  end

  def self.controller_info=(value)
    drafts_store[:controller_info] =  value
  end

  def self.controller_info
    drafts_store[:controller_info]
  end

  private

  def self.drafts_store
    Thread.current[:draft] ||= { :request_enabled_for_controller => true }
  end

  def self.config
    @@config ||= Kentouzu::Config.instance
  end
end

ActiveSupport.on_load(:active_record) do
  include Kentouzu::Model
end

ActiveSupport.on_load(:action_controller) do
  include Kentouzu::Controller
end
