class IssuesController < ApplicationController
  before_action :set_user

  def index
    @issues = @user.issues
  end
  # POST /plugins/message_system/issues
  def create
    existing_user = false
    if @user.new_record?
      existing_user = User.find_by(email: user_params[:email]).present?
      unless existing_user
        @user.update_attributes(user_params)
        cookies[:user] = @user.id
      end
    end
    if !existing_user
      # check if topic is from permitted values if no, change it to other
      @issue = @user.issues.build(issue_params)
      if @issue.save
        @message = @issue.messages.build(message_params.merge(date: Time.now))
          if @message.save
            @user.update_attributes(last_message: @message.created_at)
            extra_data = get_extra_data.merge(username: @user.username, access_token: @user.access_token, issue_hash_id: @issue.hash_id, issue_topic: @issue.topic)
            send_email(@user.email, "Issue '#{@issue.topic} #{@issue.hash_id}'", message_params[:body], 'support@vdare.com',[],'plugins/message_system/mailer/notification_letter','mailer_layout',extra_data)
          end
        flash[:notice] =  'Issue was successfully created.'
      else
        flash[:notice] =  'Something went wrong, issue can not be created '
      end
    else
      flash[:error] = 'Please use hashed link provided by email to access your messages or login'
    end
    redirect_back fallback_location: root_path
  end

  def resolve
    if !@user.new_record?
      issue = @user.issues.find_by(hash_id: params[:id])
      if issue&.update_attributes(status: "Resolved")
        redirect_back fallback_location: root_path, notice: "Issue resolved"
      else
        redirect_back fallback_location: root_path, notice: "Something went wrong"
      end
    end
  end
  # DELETE /plugins/message_system/issues/1
  private
    # Use callbacks to share common setup or constraints between actions.

    def set_user
      @user = UsersService.new({access_token: params[:access_token], user: cookies[:user]}).get_user
    end
    # Only allow a trusted parameter "white list" through.
    def issue_params
      params.require(:issue).permit(:topic, :status, :hash_id, :sender_id)
    end
    def user_params
      params.require(:user).permit(:email,:username)
    end
    def message_params
      params.require(:message).permit(:body)
    end
end
