module Kentouzu
  module Model
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_drafts(options = {})
        send :include, InstanceMethods

        class_attribute :draft_association_name
        self.draft_association_name = options[:draft] || :draft

        attr_accessor self.draft_association_name

        class_attribute :draft_class_name
        self.draft_class_name = options[:class_name] || 'Draft'

        class_attribute :ignore
        self.ignore = ([options[:ignore]].flatten.compact || []).map &:to_s

        class_attribute :if_condition
        self.if_condition = options[:if]

        class_attribute :unless_condition
        self.unless_condition = options[:unless]

        class_attribute :skip
        self.skip = ([options[:skip]].flatten.compact || []).map &:to_s

        class_attribute :only
        self.only = ([options[:only]].flatten.compact || []).map &:to_s

        class_attribute :drafts_enabled_for_model
        self.drafts_enabled_for_model = true

        class_attribute :drafts_association_name
        self.drafts_association_name = options[:drafts] || :drafts

        has_many self.drafts_association_name,
                 :class_name => draft_class_name,
                 :as         => :item,
                 :order      => "#{Kentouzu.timestamp_field} ASC, #{self.draft_class_name.constantize.primary_key} ASC",
                 :dependent  => :destroy

        define_singleton_method "new_#{drafts_association_name.to_s}".to_sym do
          Draft.where(:item_type => self.name, :event => 'create')
        end

        define_singleton_method "all_with_reified_#{drafts_association_name.to_s}".to_sym do |order_by = Kentouzu.timestamp_field, &block|
          existing_drafts = Draft.where("`drafts`.`item_type` = \"#{self.name}\" AND `drafts`.`item_id` IS NOT NULL").group_by { |draft| draft.item_id }.map { |k, v| v.sort_by { |draft| draft.created_at }.first }

          new_drafts = Draft.where("`drafts`.`item_type` = \"#{self.name}\" AND `drafts`.`item_id` IS NULL")

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

        def drafts_off
          self.drafts_enabled_for_model = false
        end

        def drafts_on
          self.drafts_enabled_for_model = true
        end
      end
    end

    module InstanceMethods
      def self.included(base)
        default_save = base.instance_method(:save)

        base.send :define_method, :save do
          if switched_on? && save_draft?
            draft = Draft.new(:item_type => self.class.base_class.to_s, :item_id => self.id, :event => self.persisted? ? 'update' : 'create', :source_type => Kentouzu.source.present? ? Kentouzu.source.class.to_s : nil, :source_id => Kentouzu.source.present? ? Kentouzu.source.id : nil, :object => self.to_yaml)

            draft.save
          else
            default_save.bind(self).call
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

      private

      def draft_class
        draft_class_name.constantize
      end

      def source_draft
        send self.class.draft_association_name
      end

      def switched_on?
        Kentouzu.enabled? && Kentouzu.enabled_for_controller? && self.class.drafts_enabled_for_model
      end

      def save_draft?
        (if_condition.blank? || if_condition.call(self)) && !unless_condition.try(:call, self)
      end
    end
  end
end
