require 'net/imap'
class MailReplyService
  
  def self.parse_mailbox
    imap = Net::IMAP.new('imap.gmail.com',993, ssl: true)
    imap.login(EMAIL_IMAP_PARAMS[:login], EMAIL_IMAP_PARAMS[:password])
    imap.examine('INBOX')
    time = Time.now # today cuz it takes only date
    first_time = Settings.all.present?
    # get  id  of first letter for today to start with if never was parsed before and store into settings
    if first_time
      first_id = imap.search(["SINCE", "#{time.strftime('%e-%b-%Y')}"]).first
      Settings.create(id_for_parser: first_id)
    else
      first_id = Settings.first.id_for_parser
    end
    # we use first id cuz passed uid is not working properly in search (show only last letter uid)
    # get all mails uids after that id
    uids = imap.uid_search("#{first_id.to_i}:*")
    # remove first elemnt from array cuz it was alredy parsed previous time
    uids.shift unless first_time
    puts "#{uids.count} new emails found"
    count = extract_data(uids)
    notice = "#{count} messages added"
    return notice
  end

  def extract_data(uids)
    count = 0
    uids.each do |uid|
      data  = imap.uid_fetch(uid, ['RFC822'])[0]
      mail = Mail.new(data.attr["RFC822"])
      # get full body to parse hash link for issue id in case when subject of the email is changed
      body = (mail.text_part || mail.html_part || mail).body.decoded.force_encoding('UTF-8')
      subject = mail.subject
      issue_id = subject.delete("'\"").split(" ").last if subject.include?("Issue")
      unless issue_id
        issue_id4 = body.split("issue-")[1].split(">")[0] if body.include?("issue-")
      end
      first_id, count = create_reply_message(issue_id, mail)
      Settings.update_attributes(id_for_parser: first_id) if uid == uids.last
    end
    # save id for next parsing
    return count
  end

  def create_reply_message(issue_id, mail)
    count = 0
    first_id = nil
    if issue_id
      email_from = mail.from[0]
      date = mail.date
      issue = Issue.find_by(hash_id: issue_id)
      if issue.present?
        user = issue.sender
        if user.email == email_from
          # parse reply to have only text
          body = ExtendedEmailReplyParser.parse mail
          message_params = {
            sender_id: user.id,
            body: body,
            created_at: date,
            updated_at: date
          }
          message = issue.messages.build(message_params)
          count += 1 if message.save
        end
        # last letter id to use in future search as start point
        puts "#{count} messages created"
        # seqno = id
        first_id = data.seqno if uid == uids.last
      end
    end
    return first_id, count
  end
end
