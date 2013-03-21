require 'test_helper'
require File.join('./lib/mailchimp','handlers', 'mandrill_delivery_handler')

class MandrillDeliveryHandlerTest < Test::Unit::TestCase
  context "when delivering a Mail::Message to the Mandrill API" do
    setup do
      @mandrill_delivery_handler = Mailchimp::MandrillDeliveryHandler.new
      @fake_mandrill_api_response = [{"email"=>"foo@bar.com", "status"=>"sent"}]

      FakeWeb.register_uri(
      :post,
      'http://mandrillapp.com/api/1.0/messages/send',
      body: @fake_mandrill_api_response.to_json
    )
    end

    should "deliver successfully" do
      message = mock_mail_message
      response = @mandrill_delivery_handler.deliver!(message)
      assert_equal @fake_mandrill_api_response, response
    end
  end
  context "get_to_for" do
    should "Return an array of hashes" do
      test_emails.each do |h|
        assert_equal h[:expected], Mailchimp::MandrillDeliveryHandler.new.__send__(:get_to_for, mock_mail(h[:params]))
      end
    end
  end

  context "get_content_for" do
    should "return the message part" do

    end
  end
  private

  def mock_mail params
    mock.tap { |m| m.stubs :to => params }
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
