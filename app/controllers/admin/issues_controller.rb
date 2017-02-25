class Admin::IssuesController < ApplicationController
  before_action :only_admin

  def index
    @issues = Issue.includes(:messages).latest
    @btns_first_row = { all: "All (#{@issues.size})",
                        open: "Open (#{@issues.opened.size})",
                        closed: " Resolved (#{@issues.resolved.size})"
            }

    params[:s] ||= "open"
    case params[:s]
      when "all"
        @issues
      when "open"
        @issues = @issues.opened
      when "closed"
        @issues = @issues.resolved
    end

    @issues = @issues.where(sender_id: params[:user]) if params[:user].present?
    @issues = @issues.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
  end

  def set_assignee
    @issue.update_attributes(assignee_id: params[:assignee_id]) if params[:assignee_id].present?
    redirect_back fallback_location: admin_path
  end

  def read_messages
    redirect_back fallback_location: admin_path if @issue.messages.update_all(status: "Read")
  end

  def reply
    @issue = Issue.find_by_id(params[:issue_id])
    issue_present =  @issue.present?
    if issue_present
      @message = @issue.messages.build(message_params.merge(is_admin_reply: true))
      saved = @message.save
      if saved
        @messages = @issue.messages
        @messages.update_all(status: "Read")
        @issue.touch
        user = @issue.sender
        #send_email(email, subject='Notification', content='', from=nil, attachs=[], template_name = nil, layout_name = nil, extra_data = {})
        extra_data = get_extra_data.merge(username: user.username, access_token: user.access_token, issue_hash_id: @issue.hash_id)
        send_email(user.email, "Reply to issue '#{@issue.subject} #{@issue.hash_id}'", message_params[:description], 'email@example.com',[],'plugins/message_system/mailer/reply_letter','mailer_layout',extra_data)
      end
    end
    respond_to do |format|
      format.js
      format.html {
        if issue_present && saved
          redirect_back fallback_location: root_path, notice: "Message sent"
        elsif issue_present
          redirect_back fallback_location: root_path, error: "Reply wasn't sent"
        else
          redirect_back fallback_location: root_path, error: "Issue not found"
        end
        }
    end
  end

  def parse
    redirect_back fallback_location: admin_path, notice: MailReplyService.parse_mailbox
  end

  def resolve
    issue = Issue.find_by_id(params[:id])
    if issue.present?
      redirect_back fallback_location: admin_path, notice: "Issue resolved" if issue.update_attributes(status: "Resolved")
    else
      redirect_back fallback_location: admin_path, error: "Issue not found"
    end
  end

  def destroy
    @issue.destroy
    redirect_back fallback_location: admin_path, notice: 'issue was successfully destroyed.'
  end
  private
  def set_issue
    @issue = Issue.find(params[:id])
  end

  def set_user
    @user = get_user
  end

  def message_params
    params.require(:message).permit(:description)
  end

  def only_admin
    unless current_user.is_admin
      redirect_to root_path
    end
  end
end
