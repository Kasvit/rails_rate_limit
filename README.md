# Rails Rate Limit

[![Gem Version](https://badge.fury.io/rb/rails_rate_limit.svg)](https://badge.fury.io/rb/rails_rate_limit)
[![Build Status](https://github.com/kasvit/rails_rate_limit/workflows/Ruby/badge.svg)](https://github.com/kasvit/rails_rate_limit/actions)

A flexible and robust rate limiting solution for Ruby on Rails applications. The gem implements a sliding window log algorithm, which means it tracks the exact timestamp of each request and calculates the count within a sliding time window. This provides more accurate rate limiting compared to fixed window approaches.

For example, if you set a limit of 100 requests per hour, and a user makes 100 requests at 2:30 PM, they won't be able to make another request until some of those requests "expire" after 2:30 PM the next hour. This prevents the common issue with fixed windows where users could potentially make 200 requests around the window boundary.

Supports rate limiting for both HTTP requests and method calls, with multiple storage backends (Redis, Memcached, Memory).
Inspired by https://github.com/rails/rails/blob/8-0-sec/actionpack/lib/action_controller/metal/rate_limiting.rb.

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
  # Required: Choose your default storage backend
  config.default_store = :redis # Available options: :redis, :memcached, :memory
  
  # Optional: Configure Redis connection (required if using Redis store)
  config.redis_connection = Redis.new(
    url: ENV['REDIS_URL'],
    timeout: 1,
    reconnect_attempts: 2
  )
  
  # Optional: Configure Memcached connection (required if using Memcached store)
  config.memcached_connection = Dalli::Client.new(
    ENV['MEMCACHED_URL'],
    { expires_in: 1.day, compress: true }
  )
  
  # Optional: Configure logging
  config.logger = Rails.logger
  
  # Optional: Configure default handler for controllers (HTTP requests)
  config.default_on_controller_exceeded = -> {
    render json: {
      error: "Too many requests",
      retry_after: response.headers["Retry-After"]
    }, status: :too_many_requests
  }
  
  # Optional: Configure default handler for methods
  config.default_on_method_exceeded = -> {
    # Your default logic for methods
    # For example: log the event, notify admins, etc.
    Rails.logger.warn("Rate limit exceeded for #{self.class.name}")
  }
end
```

## Usage

### Rate Limiting Controllers

Include the module and set rate limits for your controllers:

```ruby
class ApiController < ApplicationController
  include RailsRateLimit::Controller # include this module

  # Basic usage - limit all actions
  set_rate_limit limit: 100,            # Maximum requests allowed
                period: 1.minute        # Time window for the limit

  # Advanced usage - limit specific actions with all options
  set_rate_limit only: [:create, :update],       # Only these actions (optional)
                except: [:index, :show],         # Exclude these actions (optional)
                limit: 50,                       # Maximum requests allowed
                period: 1.hour,                  # Time window for the limit
                by: -> { current_user&.id || request.remote_ip }, # Request identifier
                store: :redis,                   # Override default store
                on_exceeded: -> {                # Custom error handler
                  render json: {
                    error: 'Custom error message',
                    plan_limit: current_user.plan.limit,
                    upgrade_url: pricing_url
                  }, status: :too_many_requests
                }
end
```

### Rate Limiting Methods

You can limit any method calls in your classes:

```ruby
class ApiClient
  include RailsRateLimit::Klass # include this module

  def make_request
    # Your API call logic here
  end

  # IMPORTANT: set_rate_limit must be called AFTER method definition 
  # Basic usage
  set_rate_limit :make_request,
                limit: 100,
                period: 1.minute

  # Advanced usage with all options
  set_rate_limit :another_method,
                limit: 10,                       # Maximum calls allowed
                period: 1.hour,                  # Time window for the limit
                by: -> { "client:#{id}" },       # Method call identifier
                store: :memcached,               # Override default store
                on_exceeded: -> {                # Custom error handler
                  notify_admin
                  log_exceeded_event
                  enqueue_retry_job
                }
end
```

### Available Options

For both controllers and methods:
- `limit`: (Required) Maximum number of requests/calls allowed
- `period`: (Required) Time period for the limit (in seconds or ActiveSupport::Duration)
- `by`: (Optional) Lambda/Proc to generate unique identifier
  - Default for controllers: `request.remote_ip`
  - Default for methods: `"#{class_name}:#{id || object_id}"`
- `store`: (Optional) Override default storage backend (`:redis`, `:memcached`, `:memory`)
- `on_exceeded`: (Optional) Custom handler for rate limit exceeded

Additional options for controllers:
- `only`: (Optional) Array of action names to limit
- `except`: (Optional) Array of action names to exclude

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

### HTTP Headers

For controller rate limiting, the following headers are automatically added:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Remaining requests in current period
- `X-RateLimit-Reset`: Time when the current period will reset (Unix timestamp)

## Storage Backends

### Redis
- Requires the `redis-rails` gem
- Best for distributed systems
- Automatic cleanup of expired data
- Atomic operations ensure accuracy
- Recommended for production use

### Memcached
- Requires the `dalli` gem
- Good balance of performance and features
- Automatic cleanup via TTL
- Works well in distributed environments
- Good option if you're already using Memcached

### Memory
- No additional dependencies
- Perfect for development or single-server setups
- Data is lost on server restart
- Not suitable for distributed systems
- Thread-safe implementation

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kasvit/rails_rate_limit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
