class CreateIssues < ActiveRecord::Migration[5.0]
  def change
    create_table :issues do |t|
      t.string :topic
      t.string :status
      t.string :hash_id
      t.integer :sender_id

      t.timestamps
    end
    add_index :issues, :hash_id
    add_index :issues, :sender_id
  end
end
