module Mailchimp
  class MandrillDeliveryHandler
    attr_accessor :settings

    def initialize(options = {})
      self.settings = {:track_opens => true, :track_clicks => true, :from_name => 'Mandrill Email Delivery Handler'}.merge(options)
    end

    def deliver!(message)
      self.settings[:return_response] = Mailchimp::Mandrill.new(api_key_for message).messages_send get_message_payload(message)
    end

    private

    def api_key_for message
      message.header['api-key'].blank? ? settings[:api_key] : message.header['api-key']
    end

    def get_message_payload message
      {
        :track_opens  => settings[:track_opens],
        :track_opens => settings[:track_opens],
        :track_clicks => settings[:track_clicks],
        :message => {
          :subject => message.subject,
          :from_name => message.header['from-name'].blank? ? settings[:from_name] : message.header['from-name'],
          :from_email => message.from.first,
          :to => get_to_for(message),
          :headers => {'Reply-To' => message.reply_to.nil? ? nil : message.reply_to }
        }
      }.tap do |payload|
        [:html, :text].each do |format|
          payload[:message][format] = get_content_for(message, format).to_s
        end
        payload[:tags] = settings[:tags] if settings[:tags]
        payload[:message][:bcc_address] = message.bcc.first if message.bcc && !message.bcc.empty?
      end
    end

    def get_to_for(message)
      to = message.to.kind_of?(Array) ? message.to : [message.to]
      to.collect do |m|
        m.kind_of?(Hash) ? m : { email: m, name: m }
      end
    end

    def get_content_for(message, format)
      if(message.multipart?)
        message.send(:"#{format.to_s}_part").body
      else
        message.body if is_format?(message, format)
      end
    end



    def is_format? message, format
      (message.text?) == (format.to_sym == :text)
    end
  end
end

if defined?(ActionMailer)
  ActionMailer::Base.add_delivery_method(:mailchimp_mandrill, Mailchimp::MandrillDeliveryHandler)
end