# Log Logins

A simple library to provide tooling to allow access/login attempts to be fully logged and automatically blocked when there are too many failed login attempts.

* Provide a full audit trail for login attempts to an application. Both user and API access attempts should be supported.
* Automatically temporarily block logins for a user/token when there are too many failed login attempts.
* Automatically temporarily block logins for an IP address when there are too many failed login attempts.
* Provide hooks to allow events to be registered when logins are blocked etc...

This library is designed to be used within a Rails application and uses ActiveRecord as a base.

By default, users are blocked for 1 hour after 10 failed attempts.

## Installation

```ruby
gem 'log_logins'
```

Next, you need to install the migrations into your application.

```bash
$ rake log_logins:install:migrations
$ rails db:migrate
```

## Usage

The library needs to be told whenever there is a login attempt for your application. The actual placement of such a method call will depend on your application.

```ruby
def authenticate(username, password, ip)
  # When a login attempt fails, you need to call the `failed` method.
  LogLogins.fail(username, self, ip)

  # When a login attempt is successful, you need to call the `success` method.
  LogLogins.success(username, self, ip)
end
```

If a login should not be permitted a `LogLogins::LoginBlocked` error will be raised from either `fail` or `success`. Remember, just because a login is successful, it doesn't mean it won't be blocked. This should be rescued in your controllers to present a suitable response to the blocked user.

The user object passed to the `fail` or `success` objects must be instance of an ActiveRecord model (for example `User` or `APIToken`). It may also be a string for occasions when there's a login attempt for but there is no corresponding object in the database (for example, you may provide the raw `username` that was provided with the login attempt).

### Accessing the log

The `LogLogins::Event` class is an ActiveRecord model for each login event that is used. You can use this to generate a list of every login attempt to your application.

You may, if you wish, include the `LogLogins::User` module into any model who's login attempts are being logged. This will provide you with a `login_events` relationship.

```ruby
class User < ApplicationRecord
  include LogLogins::User
end
```

### Unblocking

You can use either of the two methods below to unblock users or IP addresses that get blocked.

```ruby
# To unblock a specific user account
LogLogins.unblock_user(user)

# To unblock an IP address
LogLogins.unblock_ip('1.2.3.4')
```

## Configuration

Some configuration options are available:

```ruby
LogLogins.configure do |config|

  # Set the name of the table where login events will be stored
  config.events_table_name = 'login_events'

  # Set the length of time blocks should remain in place (in seconds)
  config.block_time = 1.hour

  # Set the number of attempts allowed before blocking (if the user was found)
  config.attempts_before_block = 10

  # Set the number of attempts allowed before block (if no user is found, blocks the IP)
  config.attempts_before_block_on_ip = 10

  # You can also add callbacks here...

  config.on(:blocked) do |event|
    # Something to happen when logins are blocked... maybe send an email?

    if event.first_block_in_series? && event.user.is_a?(User)
      UserMailer.user_login_blocked(event).deliver_later
    end
  end

  config.on(:success) do |event|
    # Something to happen on successful logins.
  end

  config.on(:fail) do |event|
    # Something to happen on failed logins
  end

end
```
