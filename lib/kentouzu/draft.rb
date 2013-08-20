class Draft < ActiveRecord::Base
  attr_accessible :item_type, :item_id, :event, :source_type, :source_id, :object

  belongs_to :item, :polymorphic => true

  belongs_to :source, :polymorphic => true

  validates_presence_of :event

  def self.with_item_keys(item_type, item_id)
    scoped :conditions => { :item_type => item_type, :item_id => item_id }
  end

  def self.creates
    where :event => 'create'
  end

  def self.updates
    where :event => 'update'
  end

  scope :subsequent, lambda { |draft| where(["#{self.primary_key} > ?", draft]).order("#{self.primary_key} ASC") }

  scope :preceding, lambda { |draft| where(["#{self.primary_key} < ?}", draft]).order("#{self.primary_key} DESC") }

  scope :following, lambda { |timestamp| where(["#{Kentouzu.timestamp_field} > ?"], timestamp).order("#{Kentouzu.timestamp_field} ASC, #{self.primary_key} ASC") }

  scope :between, lambda { |start_time, end_time| where(["#{Kentouzu.timestamp_field} > ? AND #{Kentouzu.timestamp_field} < ?", start_time, end_time]).order("#{Kentouzu.timestamp_field} ASC, #{self.primary_key} ASC") }

  def reify(options = {})
    without_identity_map do
      options[:has_one] = 3 if options[:has_one] == true
      options.reverse_merge! :has_one => false

      unless object.nil?
        #This appears to be necessary if for some reason the draft's model hasn't been loaded (such as when done in the console).
        require self.item_type.underscore

        loaded_object = YAML::load object

        if item
          model = item
        else
          inheritance_column_name = item_type.constantize.inheritance_column

          class_name = loaded_object.respond_to?(inheritance_column_name.to_sym) && loaded_object.send(inheritance_column_name.to_sym).present? ? loaded_object.send(inheritance_column_name.to_sym) : item_type

          klass = class_name.constantize

          model = klass.new
        end

        loaded_object.attributes.each do |key, value|
          if model.respond_to?("#{key}=")
            model.send :write_attribute, key.to_sym, value
          else
            logger.warn "Attribute #{key} does not exist on #{item_type} (Draft ID: #{id})."
          end
        end

        model.send "#{model.class.draft_association_name}=", self

        unless options[:has_one] == false
          reify_has_ones model, options[:has_one]
        end

        model
      end
    end
  end

  def approve
    model = self.reify

    if model
      model.without_drafts :save

      if event == 'update'
        previous_drafts = Draft.where(["item_type = ? AND item_id = ? AND created_at <= ? AND id <= ?", model.class.to_s, model.id, self.created_at.strftime('%Y-%m-%d %H:%M:%S'), self.id])

        previous_drafts.each do |previous_draft|
          previous_draft.delete
        end
      end
    end

    self.destroy

    model
  end

  def reject
    self.destroy
  end

  private

  def without_identity_map(&block)
    if defined?(ActiveRecord::IdentityMap) && ActiveRecord::IdentityMap.respond_to?(:without)
      ActiveRecord::IdentityMap.without &block
    else
      block.call
    end
  end

  def reify_has_ones(model, lookback)
    model.class.reflect_on_all_associations(:has_one).each do |association|
      child = model.send association.name

      if child.respond_to? :draft_at
        if (child_as_it_was = child.draft_at(send(Kentouzu.timestamp_field) - lookback.seconds))
          child_as_it_was.attributes.each do |key, value|
            model.send(association.name).send :write_attribute, key.to_sym, value rescue nil
          end
        else
          model.send "#{association.name}=", nil
        end
      end
    end
  end
end
