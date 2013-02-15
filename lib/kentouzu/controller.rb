module Kentouzu
  module Controller
    def self.included base
      base.before_filter :set_drafts_source
      base.before_filter :set_drafts_controller_info
      base.before_filter :set_drafts_enabled_for_controller
    end

    protected

    def user_for_drafts
      current_user rescue nil
    end

    def info_for_drafts
      {}
    end

    def drafts_enabled_for_controller
      true
    end

    private

    def set_drafts_source
      ::Kentouzu.source = user_for_drafts
    end

    def set_drafts_controller_info
      ::Kentouzu.controller_info = info_for_drafts
    end

    def set_drafts_enabled_for_controller
      ::Kentouzu.enabled_for_controller = drafts_enabled_for_controller
    end
  end
end
