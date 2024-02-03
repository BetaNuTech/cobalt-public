require 'test_helper'

module Alerts
  module Commands
    class SendSlackMessageTest < ActiveSupport::TestCase
      def setup 
        @property = properties(:home)
        @channel = @property.slack_channel
        @test_message = "This is a test message."
        @command = Alerts::Commands::SendSlackMessage.new(@test_message, 
          @channel)
      end
      
      test "sends on slack" do 
        client = mock()
        Slack::Web::Client.expects(:new).returns(client)
        client.expects(:chat_postMessage).with({channel: @channel, text: @test_message, 
          as_user: true, link_names: true})    
        
        @command.perform
      end
      
      test "catches exceptions from Slack" do 
        client = mock()
        Slack::Web::Client.expects(:new).returns(client)
        
        client.expects(:chat_postMessage).with(channel: @channel, text: @test_message, 
          as_user: true, link_names: true).raises(StandardError, 'message')    
        
        @command.perform
      end
    end
  end
end
