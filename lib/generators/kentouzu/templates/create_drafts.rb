class CreateDrafts < ActiveRecord::Migration
  def change
    create_table :kentouzu do |t|
      t.string :item_type,   :null => false
      t.integer :item_id,    :null => false
      t.string :event,       :null => false
      t.string :source_type
      t.string :source_id
      t.text :object
      t.datetime :created_at
      t.datetime :updated_at
    end

    change_table :drafts do |t|
      t.index :item_type
      t.index :item_id
      t.index :event
      t.index :source_type
      t.index :source_id
      t.index :created_at
      t.index :updated_at
    end
  end
end
