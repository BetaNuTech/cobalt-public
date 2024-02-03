require 'test_helper'

module Alerts
  module Commands
    class SendTest < ActiveSupport::TestCase
      def setup 
        @property = properties(:home)
        @test_message = "This is a test message."
        @command = Alerts::Commands::Send.new(@test_message, @property.id)
      end
      
      test "sends on slack" do 
        send_slack_message = mock()
        Alerts::Commands::SendSlackMessage.expects(:new).with(@test_message, 
          @property.slack_channel).returns(send_slack_message)
        Job.expects(:create).with(send_slack_message)
        
        @command.perform
      end
      
      test "do not send on slack if property does not have a slack channel" do 
        @property.slack_channel = nil
        @property.save!
        Alerts::Commands::SendSlackMessage.expects(:new).never
        
        @command.perform        
      end
      
      test "catches exceptions from Slack" do 
        send_slack_message = mock()
        Alerts::Commands::SendSlackMessage.expects(:new).with(@test_message, 
          @property.slack_channel).raises(StandardError, 'message')
        
        @command.perform
      end
    end
  end
end
