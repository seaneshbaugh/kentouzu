class Draft < ActiveRecord::Base
  if Kentouzu.active_record_protected_attributes?
    attr_accessible :item_type, :item_id, :event, :source_type, :source_id, :object
  end

  belongs_to :item, :polymorphic => true

  belongs_to :source, :polymorphic => true

  validates_presence_of :event

  def self.with_item_keys(item_type, item_id)
    where :item_type => item_type, :item_id => item_id
  end

  def self.with_source_keys(source_type, source_id)
    where :source_type => source_type, :source_id => source_id
  end

  def self.creates
    where :event => 'create'
  end

  def self.updates
    where :event => 'update'
  end

  def subsequent(obj, timestamp_arg = false)
    if timestamp_arg != true && self.primary_key_is_int?
      where(arel_table[primary_key].gt(obj.id)).order(arel_table[primary_key].asc)
    else
      obj = obj.send(Kentouzu.timestamp_field) if obj.is_a?(self)

      where(arel_table[Kentouzu.timestamp_field].gt(obj)).order(self.timestamp_sort_order)
    end
  end

  def preceding(obj, timestamp_arg = false)
    if timestamp_arg != true && self.primary_key_is_int?
      where(arel_table[primary_key].lt(obj.id)).order(arel_table[primary_key].asc)
    else
      obj = obj.send(Kentouzu.timestamp_field) if obj.is_a?(self)

      where(arel_table[Kentouzu.timestamp_field].lt(obj)).order(self.timestamp_sort_order)
    end
  end

  def following(timestamp)
    where(arel_table[Kentouzu.timestamp_field].gt(timestamp)).order(self.timestamp_sort_order)
  end

  def between(start_time, end_time)
    where(arel_tabl[Kentouzu.timestamp_field].gt(start_time).and(arel_table[Kentouzu.timestamp_field].lt(end_time))).order(self.timestamp_sort_order)
  end

  def timestamp_sort_order(direction = 'asc')
    [arel_table[Kentouzu.timestamp_field].send(direction.downcase)].tap do |array|
      array << arel_table[primary_key].send(direction.downcase) if self.primary_key_is_int?
    end
  end

  # Restore the item from this draft.
  #
  # Options:
  # :has_one      Set to `false` to disable has_one reification.
  #               Set to a float to change the lookback time.
  def reify(options = {})
    return nil if object.nil?

    without_identity_map do
      options[:has_one] = 3 if options[:has_one] == true

      options.reverse_merge! :has_one => false

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

      has_many_associations = model.class.reflect_on_all_associations(:has_many).reject { |association| association.name == :drafts || association.options.keys.include?(:through) }.map { |association| association.name }

      has_and_belongs_to_many_associations = model.class.reflect_on_all_associations(:has_and_belongs_to_many).map { |association| association.plural_name }

      loaded_object.each do |key, value|
        if model.respond_to?("#{key}=")
          if has_many_associations.include?(key.to_sym)
            model.send "#{key}=".to_sym, value.map { |v| model.send(key.to_sym).proxy_association.klass.new(v) }
          elsif has_and_belongs_to_many_associations.include?(key.gsub('_ids', '').pluralize)
            model.send "#{key.gsub('_ids', '').pluralize}=".to_sym, model.class.reflect_on_all_associations(:has_and_belongs_to_many).select { |association| association.plural_name == key.gsub('_ids', '').pluralize }.first.class_name.constantize.where(id: value)
          else
            model.send :write_attribute, key.to_sym, value
          end
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

  def approve
    warn 'DEPRECATED: `approve` should be handled by your application, not Kentouzu. Will be removed in Kentouzu 0.3.0.'

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
    warn 'DEPRECATED: `reject` should be handled by your application, not Kentouzu. Will be removed in Kentouzu 0.3.0.'

    self.destroy
  end

  def primary_key_is_int?
    @primary_key_is_int ||= columns_hash[primary_key].type == :integer
  rescue
    true
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
