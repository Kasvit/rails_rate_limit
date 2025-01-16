# Rails Rate Limit

[![Gem Version](https://badge.fury.io/rb/rails_rate_limit.svg)](https://badge.fury.io/rb/rails_rate_limit)
[![Build Status](https://github.com/kasvit77/rails_rate_limit/workflows/Ruby/badge.svg)](https://github.com/kasvit77/rails_rate_limit/actions)

A flexible and robust rate limiting solution for Ruby on Rails applications. Supports rate limiting for both HTTP requests and method calls, with multiple storage backends (Redis, Memcached, Memory).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_rate_limit'
```

And then execute:

```bash
$ bundle install
```

## Configuration

Create an initializer `config/initializers/rails_rate_limit.rb`:

```ruby
RailsRateLimit.configure do |config|
  config.default_store = :redis # or :memcached, or :memory
  config.redis_connection = Redis.new # optional, if using Redis
  config.memcached_connection = Dalli::Client.new # optional, if using Memcached
  
  # Default handler for controllers (HTTP requests)
  config.default_on_controller_exceeded = ->(controller) {
    controller.render json: { error: 'Too many requests' }, status: :too_many_requests
  }
  
  # Default handler for methods
  config.default_on_method_exceeded = -> { 
    # Your default logic for methods
    # The return value will be discarded, method will return nil
  }
end
```

## Usage

### Rate Limiting Controllers

Include the module and set rate limits for your controllers:

```ruby
class ApiController < ApplicationController
  include RailsRateLimit::Controller

  # Limit all actions to 100 requests per minute
  set_rate_limit limit: 100, period: 1.minute

  # Or limit specific actions with custom options
  set_rate_limit only: [:create, :update],
                limit: 50,
                period: 1.hour,
                by: -> { current_user.id },
                on_exceeded: -> {
                  render json: { error: 'Custom error message' }, status: :too_many_requests
                }
end
```

### Rate Limiting Methods

You can limit any method calls in your classes:

```ruby
class ApiClient
  include RailsRateLimit::Klass

  def make_request
    # Your API call logic here
  end

  # IMPORTANT: set_rate_limit must be called AFTER method definition
  set_rate_limit :make_request,
                limit: 100,
                period: 1.minute,
                by: -> { "client:#{id}" }

  # Custom error handling
  set_rate_limit :another_method,
                limit: 10,
                period: 1.hour,
                on_exceeded: -> { 
                  # Custom logic when limit is exceeded
                  notify_admin
                  # Any return value will be discarded, method will return nil
                }
end
```

### Available Options

- `limit`: Maximum number of requests/calls allowed
- `period`: Time period for the limit (in seconds or ActiveSupport::Duration)
- `by`: Lambda/Proc to generate unique identifier (default: IP for controllers, "ClassName:id" for methods)
- `store`: Override default storage backend
- `on_exceeded`: Custom handler for rate limit exceeded

### Rate Limit Exceeded Handling

The gem provides different default behaviors for controllers and methods:

1. For controllers (HTTP requests):
   - The `on_exceeded` handler (or `default_on_controller_exceeded` if not specified) is called
   - By default, returns HTTP 429 with a JSON error message
   - Headers are automatically added with limit information
   - The handler's return value is used (usually render/redirect)

2. For methods:
   - The `on_exceeded` handler (or `default_on_method_exceeded` if not specified) is called
   - The event is logged if a logger is configured
   - Returns `nil` after handler execution to indicate no result
   - No exception is raised, making it easier to handle in your code

You can customize both default handlers in the configuration:

```ruby
RailsRateLimit.configure do |config|
  # Custom default handler for controllers
  config.default_on_controller_exceeded = ->(controller) {
    controller.redirect_to "/", alert: "Please try again later"
  }
  
  # Custom default handler for methods
  config.default_on_method_exceeded = -> {
    # Your default logic for methods
    # Method will return nil after handler execution
  }
end
```

### HTTP Headers

For controller rate limiting, the following headers are automatically added:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Remaining requests in current period
- `X-RateLimit-Reset`: Time when the current period will reset (Unix timestamp)

## Storage Backends

### Redis
Requires the `redis-rails` gem. Best for distributed systems.

### Memcached
Requires the `dalli` gem. Good balance of performance and features.

### Memory
No additional dependencies. Perfect for development or single-server setups.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kasvit77/rails_rate_limit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
