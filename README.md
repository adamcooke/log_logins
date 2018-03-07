# Log Logins

A simple library to provide tooling to allow access/login attempts to be fully logged and automatically blocked when there are too many failed login attempts.

* Provide a full audit trail for login attempts to an application. Both user and API access attempts should be supported.
* Automatically temporarily block logins for a user/token when there are too many failed login attempts.
* Automatically temporarily block logins for an IP address when there are too many failed login attempts.
* Provide hooks to allow events to be registered when logins are blocked etc...

This library is designed to be used within a Rails application and uses ActiveRecord as a base.

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
# When a login attempt fails, you need to call the `failed` method.
LogLogins.fail(user, :ip => request.ip, :user_agent => request.user_agent)

# When a login attempt is successful, you need to call the `success` method.
LogLogins.success(user, :ip => request.ip, :user_agent => request.user_agent)
```

If a login should not be permitted a `LogLogins::LoginBlocked` error will be raised from either `fail` or `success`. Remember, just because a login is successful, it doesn't mean it won't be blocked.

The user object passed to the `fail` or `success` objects must be instance of an ActiveRecord model (for example `User` or `APIToken`). It may also be a string for occasions when there's a login attempt for but there is no corresponding object in the database (for example, you may provide the raw `username` that was provided with the login attempt).

### Accessing the log

The `LogLogins::Event` class is an ActiveRecord model for each login event that is used. You can use this to generate a list of every login attempt to your application.

You may, if you wish, include the `LogLogins::User` module into any model who's login attempts are being logged. This will provide you with a `login_events` relationship.

```ruby
class User < ApplicationRecord
  include LogLogins::User
end
```

### E-Mailing when logins are blocked

You can register event handlers on the global configuration which will be automatically invoked.

```ruby
LogLogins.configure do |config|

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
