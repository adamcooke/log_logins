require 'spec_helper'
require 'log_logins/event'

describe LogLogins::Event do

  subject(:user) { User.create!(:username => 'tester') }

  context ".log" do
    it "should create a log event" do
      event = LogLogins::Event.log('Success', 'tester', user, '1.2.3.4')
      expect(event).to be_a(LogLogins::Event)
    end

    it "should raise an error if invalid" do
      expect { LogLogins::Event.log('InvalidAction', 'tester', user, '1.2.3.4') }.to raise_error(LogLogins::InvalidLogEventError)
    end
  end

  context ".user_blocked?" do
    it "should be false when there are no login attempts" do
      expect(LogLogins::Event.user_blocked?(user)).to be false
    end

    it "should be true when there are more than the prescribed number of attempts" do
      10.times { LogLogins::Event.log('Failed', 'tester', user, '1.2.3.4') }
      expect(LogLogins::Event.user_blocked?(user)).to be true
    end

    it "should be false when the failed logins are older than an hour ago" do
      allow(Time).to receive(:now).and_return(Time.now - 3601)
      10.times { LogLogins::Event.log('Failed', 'tester', user, '1.2.3.4') }
      allow(Time).to receive(:now).and_call_original
      expect(LogLogins::Event.user_blocked?(user)).to be false
    end

    it "should be false when there are no enough failed logins" do
      5.times { LogLogins::Event.log('Failed', 'tester', user, '1.2.3.4') }
      expect(LogLogins::Event.user_blocked?(user)).to be false
    end

    it "should reset when there is a successful login" do
      10.times { LogLogins::Event.log('Failed', 'tester', user, '1.2.3.4') }
      expect(LogLogins::Event.user_blocked?(user)).to be true
      LogLogins::Event.log('Success', 'tester', user, '1.2.3.4')
      expect(LogLogins::Event.user_blocked?(user)).to be false
    end

    it "should work with multiple users" do
      # Fail some logins
      simulate_failed_logins(10, 'tester', user, '1.2.3.4')
      expect(LogLogins::Event.user_blocked?(user)).to be true
      # Have a successful login for another user
      user2 = User.create!(:username => "tester2")
      LogLogins::Event.log('Success', 'tester2', user2, '1.2.3.4')
      # Make sure the original user is still blocked
      expect(LogLogins::Event.user_blocked?(user)).to be true
    end
  end

  context ".ip_blocked?" do
    it "should be false when there are no login attempts" do
      expect(LogLogins::Event.ip_blocked?('1.2.3.4')).to be false
    end

    it "should be true when there are more than the prescribed number of attempts" do
      10.times { LogLogins::Event.log('Failed', 'tester', nil, '1.2.3.4') }
      expect(LogLogins::Event.ip_blocked?('1.2.3.4')).to be true
    end

    it "should be false when the failed logins are older than an hour ago" do
      allow(Time).to receive(:now).and_return(Time.now - 3601)
      10.times { LogLogins::Event.log('Failed', 'tester', nil, '1.2.3.4') }
      allow(Time).to receive(:now).and_call_original
      expect(LogLogins::Event.ip_blocked?('1.2.3.4')).to be false
    end

    it "should be false when there are no enough failed logins" do
      5.times { LogLogins::Event.log('Failed', 'tester', nil, '1.2.3.4') }
      expect(LogLogins::Event.ip_blocked?('1.2.3.4')).to be false
    end

    it "should work with multiple users" do
      # Fail some logins
      simulate_failed_logins(10, 'tester', nil, '1.2.3.4')
      expect(LogLogins::Event.ip_blocked?('1.2.3.4')).to be true
      # Have a successful login for another user
      LogLogins::Event.log('Success', 'tester2', nil, '1.2.3.5')
      # Make sure the original user is still blocked
      expect(LogLogins::Event.ip_blocked?('1.2.3.4')).to be true
    end

  end

  context "#previous" do
    it "should return nil if there are no previous logins" do
      event = LogLogins::Event.log('Success', 'tester', user, '1.2.3.4')
      expect(event.previous).to be nil
    end

    it "should reteurn the previous event" do
      event1 = LogLogins::Event.log('Success', 'tester', user, '1.2.3.4')
      event2 = LogLogins::Event.log('Success', 'tester', User.create!(:username => 'another'), '1.2.3.4')
      event3 = LogLogins::Event.log('Success', 'tester', user, '1.2.3.4')
      expect(event3.previous).to eq event1
    end

    it "should reteurn the previous event" do
      event1 = LogLogins::Event.log('Success', 'tester', nil, '1.2.3.4')
      event2 = LogLogins::Event.log('Success', 'tester', nil, '1.2.3.5')
      event3 = LogLogins::Event.log('Success', 'tester', nil, '1.2.3.4')
      expect(event3.previous).to eq event1
    end
  end

  context "#first_block_in_series?" do
    it "should be true for the first block" do
      event = LogLogins::Event.log('Blocked', 'tester', user, '1.2.3.4')
      expect(event.first_block_in_series?).to be true
    end

    it "should not be true for any others" do
      event1 = LogLogins::Event.log('Blocked', 'tester', user, '1.2.3.4')
      event2 = LogLogins::Event.log('Blocked', 'tester', user, '1.2.3.4')
      expect(event1.first_block_in_series?).to be true
      expect(event2.first_block_in_series?).to be false
    end
  end

  context ".prune" do
    it "should return 0 when no records to prune" do
      expect(LogLogins::Event.prune).to eq 0
    end

    it "should return more than 0 when more to delete" do
      allow(Time).to receive(:now).and_return(12.months.ago)
      simulate_failed_logins(5, 'tester', user, '1.2.3.4')
      allow(Time).to receive(:now).and_call_original
      expect(LogLogins::Event.prune).to eq 5
    end
  end


end
