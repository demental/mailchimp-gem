module Mailchimp
  class MandrillDeliveryHandler
    attr_accessor :settings

    def initialize(options = {})
      self.settings = {:track_opens => true, :track_clicks => true, :from_name => 'Mandrill Email Delivery Handler'}.merge(options)
    end

    def deliver!(message)
      message_payload = {
        :track_opens => settings[:track_opens],
        :track_clicks => settings[:track_clicks],
        :message => {
          :subject => message.subject,
          :from_name => settings[:from_name],
          :from_email => message.from.first,
          :to => get_to_for(message)
        }
      }

      [:html, :text].each do |format|
        content = get_content_for(message, format)
        message_payload[:message][format] = content unless content.blank?
      end

      message_payload[:tags] = settings[:tags] if settings[:tags]

      api_key = message.header['api-key'].blank? ? settings[:api_key] : message.header['api-key']

      Mailchimp::Mandrill.new(api_key).messages_send(message_payload)
    end

    private

    def get_to_for(message)
      to = message.to.kind_of?(Array) ? message.to : [message.to]
      to.collect do |m|
        m.kind_of?(Hash) ? m : { email: m, name: m }
      end
    end

    def get_content_for(message, format)
      message.send(:"body_#{format.to_s}").to_s
    end

  end
end

if defined?(ActionMailer)
  ActionMailer::Base.add_delivery_method(:mailchimp_mandrill, Mailchimp::MandrillDeliveryHandler)
end