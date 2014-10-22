module Kentouzu
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      # By calling this in your model all subsequent calls to save will instead create a draft.
      # Drafts are available through the `drafts` association.
      #
      # Options:
      # :class_name   The name of a custom Draft class. Should inherit from `Kentouzu::Draft`.
      #               Default is `'Draft'`.
      # :draft        The name for the method which returns the draft the instance was reified from.
      #               Default is `:draft`.
      # :drafts       The name to use for the drafts association.
      #               Default is `:drafts`.
      # :if           Proc that allows you to specify the conditions under which drafts are made.
      # :ignore       An Array of attributes that will be ignored when creating a `Draft`.
      #               Can also accept a Has as an argument where each key is the attribute to ignore (either
      #               a `String` or `Symbol`) and each value is a `Proc` whose return value, `true` or
      #               `false`, determines if it is ignored.
      # :meta         A hash of extra data to store. Each key in the hash (either a `String` or `Symbol`)
      #               must be a column on the `drafts` table, otherwise it is ignored. You must add these
      #               columns yourself. The values are either objects or procs (which are called with `self`,
      #               i.e. the model the draft is being made from).
      # :on           An array of events that will cause a draft to be created.
      #               Defaults to `[:create, :update, :destroy]`.
      # :only         Inverse of the `:ignore` option. Only the attributes supplied will be passed along to
      #               the draft.
      # :unless       Proc that allows you to specify the conditions under which drafts are not made.
      def has_drafts(options = {})
        # Only include the instance methods when this `has_drafts` is called to avoid cluttering up models.
        send :include, InstanceMethods

        # Add `before_draft_save`, `after_draft_save`, and `around_draft_save` callbacks.
        send :define_model_callbacks, :draft_save

        class_attribute :draft_association_name
        self.draft_association_name = options[:draft] || :draft

        # The draft this instance was reified from.
        attr_accessor self.draft_association_name

        class_attribute :draft_class_name
        self.draft_class_name = options[:class_name] || 'Draft'

        class_attribute :draft_options
        self.draft_options = options.dup

        [:ignore, :only].each do |option|
          draft_options[option] = [draft_options[option]].flatten.compact.map { |attr| attr.is_a?(Hash) ? attr.stringify_keys : attr.to_s }
        end

        draft_options[:meta] ||= {}

        class_attribute :drafts_association_name
        self.drafts_association_name = options[:drafts] || :drafts

        if ActiveRecord::VERSION::MAJOR >= 4 # `has_many` syntax for specifying order uses a lambda in Rails 4
          has_many self.drafts_association_name,
                   lambda { order("#{Kentouzu.timestamp_field} ASC, #{self.primary_key} ASC") },
                   :class_name => draft_class_name,
                   :as         => :item,
                   :dependent  => :destroy
        else
          has_many self.drafts_association_name,
                   :class_name => draft_class_name,
                   :as         => :item,
                   :order      => "#{Kentouzu.timestamp_field} ASC, #{self.draft_class.primary_key} ASC",
                   :dependent  => :destroy
        end

        define_singleton_method "new_#{drafts_association_name.to_s}".to_sym do
          Draft.where(:item_type => self.name, :event => 'create')
        end

        define_singleton_method "all_with_reified_#{drafts_association_name.to_s}".to_sym do |order_by = Kentouzu.timestamp_field, &block|
          existing_drafts = Draft.where("`drafts`.`item_type` = \"#{self.base_class.name}\" AND `drafts`.`item_id` IS NOT NULL").group_by { |draft| draft.item_id }.map { |_, v| v.sort_by { |draft| draft.created_at }.last }

          new_drafts = Draft.where("`drafts`.`item_type` = \"#{self.base_class.name}\" AND `drafts`.`item_id` IS NULL")

          existing_reified_objects = existing_drafts.map { |draft| draft.reify }

          new_reified_objects = new_drafts.map do |draft|
            object = draft.reify

            object.send "#{Kentouzu.timestamp_field}=", draft.created_at

            object
          end

          existing_objects = self.all.reject { |object| existing_reified_objects.map { |reified_object| reified_object.id }.include? object.id }

          all_objects = (existing_objects + existing_reified_objects + new_reified_objects).sort_by { |object| object.send order_by }

          if block
            all_objects.select! { |object| block.call(object) }
          end

          all_objects
        end

        def drafts_off!
          Kentouzu.enabled_for_model(self, false)
        end

        def drafts_off
          warn 'DEPRECATED: use `drafts_off!` instead of `drafts_off`. Will be removed in Kentouzu 0.3.0.'

          self.drafts_off!
        end

        def drafts_on!
          Kentouzu.enabled_for_model(self, true)
        end

        def drafts_on
          warn 'DEPRECATED: use `drafts_on!` instead of `drafts_on`. Will be removed in Kentouzu 0.3.0.'

          self.drafts_on!
        end

        def drafts_enabled_for_model?
          Kentouzu.enabled_for_model?(self)
        end

        def draft_class
          @draft_class ||= draft_class_name.constantize
        end
      end
    end

    module InstanceMethods
      # Override the default `save` method and replace it with one that checks to see if a draft should be saved.
      # If a draft should be saved the original object instance is left untouched and a new draft is created.
      def self.included(base)
        default_save = base.instance_method(:save)

        base.send :define_method, :save do
          if switched_on? && save_draft?
            save_draft
          else
            default_save.bind(self).call
          end
        end

        default_save_with_bang = base.instance_method(:save!)

        base.send :define_method, :save! do
          if switched_on? && save_draft?
            save_draft
          else
            default_save_with_bang.bind(self).call
          end
        end
      end

      def live?
        source_draft.nil?
      end

      def draft_at(timestamp, reify_options = {})
        v = send(self.class.versions_association_name).following(timestamp).first

        v ? v.reify(reify_options) : self
      end

      def with_drafts(method = nil)
        drafts_were_enabled = self.drafts_enabled_for_model

        self.class.drafts_on

        method ? method.to_proc.call(self) : yield
      ensure
        self.class.drafts_off unless drafts_were_enabled
      end

      def without_drafts(method = nil)
        drafts_were_enabled = self.drafts_enabled_for_model

        self.class.drafts_off

        method ? method.to_proc.call(self) : yield
      ensure
        self.class.drafts_on if drafts_were_enabled
      end

      def drafts_enabled_for_model?
        self.class.drafts_enabled_for_model?
      end

      private

      def draft_class
        draft_class_name.constantize
      end

      def source_draft
        send self.class.draft_association_name
      end

      def merge_metadata(data)
        draft_options[:meta].each do |key, value|
          if value.respond_to?(:call)
            data[key] = value.call(self)
          elsif value.is_a?(Symbol) && respond_to?(value)
            data[key] = send(value)
          else
            data[key] = value
          end
        end

        (Kentouzu.controller_info || {}).each do |key, value|
          if value.respond_to?(:call)
            data[key] = value.call(self)
          elsif value.is_a?(Symbol) && respond_to?(value)
            data[key] = send(value)
          end
        end

        data
      end

      def save_draft
        data = {
          :item_type => self.class.base_class.to_s,
          :item_id => self.id,
          :event => draft_event.to_s,
          :source_type => Kentouzu.source.present? ? Kentouzu.source.class.to_s : nil,
          :source_id => Kentouzu.source.present? ? Kentouzu.source.id : nil,
          :object => self.as_json(include: self.class.reflect_on_all_associations(:has_many).map { |a| a.name }.reject { |a| a == :drafts }).to_yaml
        }

        @draft = Draft.new(merge_metadata(data))

        run_callbacks :draft_save do
          @draft.save
        end
      end

      def draft_event
        @draft_event ||= self.persisted? ? :update : :create
      end

      def switched_on?
        Kentouzu.enabled? && Kentouzu.enabled_for_controller? && self.drafts_enabled_for_model?
      end

      def save_draft?
        on_events = Array(self.draft_options[:on])

        if_condition = self.draft_options[:if]

        unless_condition = self.draft_options[:unless]

        (on_events.empty? || on_events.include?(draft_event)) && (if_condition.blank? || if_condition.call(self)) && !unless_condition.try(:call, self)
      end
    end
  end
end
