class Issue < ApplicationRecord
  belongs_to :sender, class_name: 'User', foreign_key: :sender_id
  belongs_to :assignee, class_name: 'User', foreign_key: :assignee_id
  has_many :messages

end
