class MessagesController < ApplicationController
  def create
    if current_user.id == message_params[:receiver_id]
      redirect_to request_referrer, alert: "You cannot send a message to yourself"
    end

    conversation = Conversation.where("(sender_id = ? and receiver_id = ?) OR (sender_id = ? and receiver_id = ?)",
                                        current_user.id, message_params[:receiver_id], 
                                        message_params[:receiver_id], current_user.id
                                        ).first
    if !conversation.present?
      conversation = Conversation.create(sender_id: current_user.id, receiver_id: message_params[:receiver_id])
    end

    @message = Message.new(user_id: current_user.id,
                          conversation_id: conversation.id,
                          content: message_params[:content]
    )

    if @message.save
      redirect_to request.referrer, notice: "The message has been sent"
    else
      redirect_to request.referrer, alert: "The message could not be sent"
    end
  end

  private
  def message_params
    params.require(:message).permit(:content, :receiver_id)
  end
  
end