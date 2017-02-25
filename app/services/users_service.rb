class UsersService
  def initialize(params)
    @access_token = params[:access_token]
    @user = params[:user]
  end

  def get_user
    issue_sender = nil #current_user.present?  ? current_user : nil
    unless issue_sender.present?
      issue_sender = @access_token.present? ?  User.find_by(access_token: @access_token) : @user.present? ? User.find_by_id(@user) : User.new
    end
    return issue_sender
  end

end
