class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.integer :user_id
      t.text :body
      t.boolean :is_admin_reply
      t.string :status, default: "Pending"
      t.integer :issue_id

      t.timestamps
    end
    add_index :messages, :issue_id
  end
end
