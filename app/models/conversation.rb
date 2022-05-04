class Conversation < ApplicationRecord
  belongs_to :sender, className: "User"
  belongs_to :receiver, className: "User"

  def last_message
    message = Message.where(conversatio_id: self.id).last
    if message.present?
      return message
    else
      return Message.new updated_at: Time.now
    end
  end
  
end
