class MessagesController < ApplicationController
   before_action :set_user, only: [:create]

    def create
    @issue = @user.issues.find_by(hash_id: params[:issue_hash_id])
    issue_present = @issue.present?
    if issue_present
      @message = @issue.messages.build(message_params)
      @message.save
      @issue.touch
      extra_data = get_extra_data.merge(username: @user.username, access_token: @user.access_token, issue_hash_id: @issue.hash_id, issue_topic: @issue.topic)
      send_email(@user.email, "Issue '#{@issue.topic} #{@issue.hash_id}'", message_params[:description], 'email@example.com',[],'mailer/notification_letter','mailer_layout',extra_data)
    end
    @messages = @issue&.messages
    respond_to do |format|
      format.js
    end
  end

  private
  def set_user
    @user = UsersService.get_user
  end
end
