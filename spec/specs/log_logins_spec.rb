require 'spec_helper'

describe LogLogins do
  it "should return config" do
    expect(LogLogins.config).to be_a(LogLogins::Config)
  end

  context ".success" do
    subject(:user) { User.create!(:username => 'tester') }

    it "should log successes" do
      event = LogLogins.success('tester', user, '1.2.3.4')
      expect(event).to be_a(LogLogins::Event)
      expect(event.action).to eq 'Success'
    end

    it "should raise an error if user is blocked" do
      simulate_failed_logins(10, 'tester', user, '1.2.3.4')
      expect { LogLogins.success('tester', user, '1.2.3.4') }.to raise_error do |error|
        expect(error).to be_a LogLogins::LoginBlocked
        expect(error.event).to be_a LogLogins::Event
        expect(error.event.action).to eq 'Blocked'
      end
    end

    it "should raise an error if the IP is blocked" do
      simulate_failed_logins(10, 'tester', nil, '1.2.3.4')
      expect { LogLogins.success('tester', user, '1.2.3.4') }.to raise_error(LogLogins::LoginBlocked)
    end

    it "should call the success callback" do
      invoked = false
      callback = LogLogins.config.on(:success) { invoked = true }
      begin
        LogLogins.success('tester', user, '1.2.3.4')
        expect(invoked).to be true
      ensure
        LogLogins.config.remove_callback(:success, callback)
      end
    end

  end

  context ".fail" do
    subject(:user) { User.create!(:username => 'tester') }

    it "should log failures" do
      event = LogLogins.fail('tester', user, '1.2.3.4')
      expect(event).to be_a(LogLogins::Event)
      expect(event.action).to eq 'Failed'
    end

    it "should raise an error if user is blocked" do
      simulate_failed_logins(10, 'tester', user, '1.2.3.4')
      expect { LogLogins.fail('tester', user, '1.2.3.4') }.to raise_error do |error|
        expect(error).to be_a LogLogins::LoginBlocked
        expect(error.event).to be_a LogLogins::Event
        expect(error.event.action).to eq 'Blocked'
      end
    end

    it "should raise an error if the IP is blocked" do
      simulate_failed_logins(10, 'tester', nil, '1.2.3.4')
      expect { LogLogins.fail('tester', nil, '1.2.3.4') }.to raise_error(LogLogins::LoginBlocked)
    end

    it "should call the fail callback" do
      invoked = false
      callback = LogLogins.config.on(:fail) { invoked = true }
      begin
        LogLogins.fail('tester', user, '1.2.3.4')
        expect(invoked).to be true
      ensure
        LogLogins.config.remove_callback(:fail, callback)
      end
    end

    it "should call the blocked callback when blocked" do
      invoked = false
      callback = LogLogins.config.on(:blocked) { invoked = true }
      begin
        simulate_failed_logins(10, 'tester', user, '1.2.3.4')
        expect { LogLogins.fail('tester', user, '1.2.3.4') }.to raise_error(LogLogins::LoginBlocked)
        expect(invoked).to be true
      ensure
        LogLogins.config.remove_callback(:success, callback)
      end
    end
  end

  context ".unblock_user" do
    subject(:user) { User.create!(:username => 'tester') }

    it "should return an event" do
      event = LogLogins.unblock_user(user)
      expect(event).to be_a(LogLogins::Event)
    end

    it "should allow logins to succeed for a user" do
      simulate_failed_logins(10, 'tester', user, '1.2.3.4')
      expect { LogLogins.success('tester', user, '1.2.3.4') }.to raise_error(LogLogins::LoginBlocked)
      LogLogins.unblock_user(user)
      expect { LogLogins.success('tester', user, '1.2.3.4') }.to_not raise_error
    end
  end

  context ".unblock_ip" do
    it "should return an event" do
      event = LogLogins.unblock_ip('1.2.3.4')
      expect(event).to be_a(LogLogins::Event)
    end

    it "should allow logins to succeed for a user" do
      simulate_failed_logins(10, 'tester', nil, '1.2.3.4')
      expect { LogLogins.success('tester', nil, '1.2.3.4') }.to raise_error(LogLogins::LoginBlocked)
      LogLogins.unblock_ip('1.2.3.4')
      expect { LogLogins.success('tester', nil, '1.2.3.4') }.to_not raise_error
    end
  end


end
