require 'test_helper'
require 'pry'
require File.join('./lib/mailchimp','handlers', 'mandrill_delivery_handler')

class MandrillDeliveryHandlerTest < Test::Unit::TestCase

  def subject
    @subject ||= Mailchimp::MandrillDeliveryHandler.new
  end

  context "when delivering a Mail::Message to the Mandrill API" do

    setup do
      @fake_mandrill_api_response = [{"email"=>"foo@bar.com", "status"=>"sent"}]
      FakeWeb.register_uri(
      :post,
      'http://mandrillapp.com/api/1.0/messages/send',
      body: @fake_mandrill_api_response.to_json
    )
    end

    should "deliver successfully" do
      message = mock_mail_message
      response = subject.deliver!(message)
      assert_equal @fake_mandrill_api_response, response
    end
  end

  context "api_key_for" do
    should "Use settings by defaults" do
      subject.stubs(:settings).returns :api_key => 12345
      assert_equal 12345, subject.__send__(:api_key_for, mock_mail_message)
    end
    should "User header api-key if provided" do
      mail = mock_mail_message
      mail.stubs(:header => {'api-key' => 123} )
      assert_equal 123, subject.__send__(:api_key_for, mail)
    end
  end


  context "get_to_for" do
    should "Return an array of hashes" do
      test_emails.each do |h|
        assert_equal h[:expected], subject.__send__(:get_to_for, mock_mail(h[:params]))
      end
    end
  end

  context "get_content_for" do

    context "when multipart email" do

      should "return the correct message part" do
        message = mock_multipart_mail
        assert_equal 'The text part', subject.__send__(:get_content_for, message, :text)
        assert_equal '<p>The html part</p>', subject.__send__(:get_content_for, message, :html)
      end

    end

    context "when not multipart email" do

      should "leave the :text key empty when html email" do
        message = mock_html_mail
        assert_nil subject.__send__(:get_content_for, message, :text)
        assert_not_nil subject.__send__(:get_content_for, message, :html)
      end

      should "leave the :html key empty when text email" do
        message = mock_text_mail
        assert_not_nil subject.__send__(:get_content_for, message, :text)
        assert_nil subject.__send__(:get_content_for, message, :html)
      end

    end

  end


  context "message_payload" do
    should "return a hash" do
      assert subject.__send__(:message_payload, mock_mail_message).kind_of? Hash
    end
  end

  private

    def mock_mail params
      mock.tap { |m| m.stubs :to => params }
    end

    def mock_multipart_mail
      mock_mail_message.tap do |mail|
        mail.stubs(:multipart?).returns true
        mail.stubs(:html_part).returns mock( body: '<p>The html part</p>')
        mail.stubs(:text_part).returns mock( body: 'The text part')
      end
    end
    def mock_text_mail
      mock_mail_message.tap do |mail|
        mail.stubs(:multipart?).returns false
        mail.stubs(:text?).returns true
        mail.stubs(:body).returns 'Text body'
      end
    end
    def mock_html_mail
      mock_mail_message.tap do |mail|
        mail.stubs(:multipart?).returns false
        mail.stubs(:text?).returns false
        mail.stubs(:body).returns '<p>Html body</p>'
      end
    end
    def test_emails
      [
        { :params => "test@email", :expected => [{ :email => "test@email", :name => "test@email"}] },
        { :params => ["test@email"], :expected => [{ :email => "test@email", :name => "test@email"}] },
        { :params => { :email => "test@email", :name => "Test user" }, :expected => [{ :email => "test@email", :name => "Test user"}] },
        { :params => ["test@email", "test2@email"], :expected => [{ :email => "test@email", :name => "test@email"}, { :email => "test2@email", :name => "test2@email"}] }
      ]
    end

end
