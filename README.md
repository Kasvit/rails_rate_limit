# **Rails Rate Limit**

[![Gem Version](https://badge.fury.io/rb/rails_rate_limit.svg)](https://badge.fury.io/rb/rails_rate_limit)
[![Build Status](https://github.com/kasvit/rails_rate_limit/workflows/Ruby/badge.svg)](https://github.com/kasvit/rails_rate_limit/actions)

A flexible and robust rate limiting solution for Ruby on Rails applications. The gem implements a **sliding window log** algorithm, which means it tracks the exact timestamp of each request and calculates the count within a sliding time window. This provides more accurate rate limiting compared to fixed window approaches.

For example, if you set a limit of 100 requests per hour, and a user makes 100 requests at 2:30 PM, they won't be able to make another request until some of those requests "expire" after 2:30 PM the next hour. This prevents the common issue with fixed windows where users could potentially make 200 requests around the window boundary.

The gem supports rate limiting for both HTTP requests (in controllers) and instance method calls (in any Ruby class), with multiple storage backends (Redis, Memcached, Memory).

## Features

- Multiple storage backends (Redis, Memcached, Memory)
- Sliding window algorithm for accurate rate limiting
- Support for both controllers and Ruby classes
- Multiple rate limits for controllers
- Custom rate limit names and skipping for controllers
- Flexible configuration options
- Automatic HTTP headers
- Custom error handlers

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_rate_limit'
```

And then execute:

```bash
$ bundle install
```

Generate the initializer:

```bash
$ rails generate rails_rate_limit:install
```

This will create a configuration file at `config/initializers/rails_rate_limit.rb` with all available options commented out.

## Configuration

The generated initializer (`config/initializers/rails_rate_limit.rb`) includes all available configuration options with default values commented out. You can uncomment and modify the options you want to customize:

```ruby
RailsRateLimit.configure do |config|
  # Choose your storage backend (default: :memory)
  # Available options: :redis, :memcached, :memory
  # config.default_store = :memory

  # Configure Redis connection (required if using Redis store)
  # config.redis_connection = Redis.new(
  #   url: ENV['REDIS_URL'],
  #   timeout: 1,
  #   reconnect_attempts: 2
  # )

  # Configure Memcached connection (required if using Memcached store)
  # config.memcached_connection = Dalli::Client.new(
  #   ENV['MEMCACHED_URL'],
  #   { expires_in: 1.day, compress: true }
  # )

  # Configure logging (set to nil to disable logging)
  # config.logger = Rails.logger

  # Configure default handler for controllers (HTTP requests)
  # config.handle_controller_exceeded = -> {
  #   render json: {
  #     error: "Too many requests",
  #     retry_after: response.headers["Retry-After"]
  #   }, status: :too_many_requests
  # }

  # Configure default handler for methods
  # By default, it raises RailsRateLimit::RateLimitExceeded
  # config.handle_klass_exceeded = -> {
  #   raise RailsRateLimit::RateLimitExceeded, "Rate limit exceeded"
  # }
end
```

## Usage

### Rate Limiting Controllers

Include the module and set rate limits for your controllers:

```ruby
class UsersController < ApplicationController
  include RailsRateLimit::Controller    # include this module

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
                },
                as: :custom_rate_limit           # Custom name for rate limit (optional)
end
```

### Multiple Rate Limits

You can set multiple rate limits for a single controller or his ancestors. Each rate limit can have its own configuration:

```ruby
class ApiController < ApplicationController
  include RailsRateLimit::Controller

  # Global rate limit for all actions
  set_rate_limit limit: 1000,
                period: 1.hour,
                as: :global_rate_limit         # Custom name for rate limit (optional)

  # Stricter limit for write operations
  set_rate_limit only: [:create, :update, :destroy],
                limit: 100,
                period: 1.hour,
                as: :write_operations_limit    # Custom name for rate limit (optional)

  # Custom limit for specific action
  set_rate_limit only: [:expensive_operation],
                limit: 10,
                period: 1.day,
                as: :expensive_operation_limit # Custom name for rate limit (optional)
end
```

### Custom Rate Limit Names

You can give your rate limits custom names using the `as` option. This is useful for:
- Better logging and debugging
- Skipping specific rate limits
- Better organization of multiple limits

```ruby
class ApplicationController < ActionController::API
  include RailsRateLimit::Controller

  # Global rate limit that applies to all inherited controllers
  set_rate_limit limit: 1000,
                period: 1.hour,
                as: :global_rate_limit
end

class ApiController < ApplicationController
  # Additional limit for API endpoints
  set_rate_limit limit: 100,
                period: 1.minute,
                as: :api_rate_limit
end
```

### Skipping Rate Limits

You can skip specific rate limits for certain actions using `skip_before_action`:

```ruby
class PaymentsController < ApiController
  # Skip global rate limit for webhook endpoint
  skip_before_action :global_rate_limit, only: [:webhook]

  # Skip API rate limit for status check
  skip_before_action :api_rate_limit, only: [:status]

  def webhook
    # This action will ignore global rate limit (custom name)
  end

  def status
    # This action will ignore API rate limit (custom name)
  end
end
```

### Rate Limiting Methods

You can limit both instance and class methods in your classes:

```ruby
class ApiClient
  include RailsRateLimit::Klass

  # Instance method
  def make_request
    # Your API call logic here
  end

  # Class method
  def self.bulk_request
    # Your API call logic here
  end

  # Rate limit for instance method
  set_rate_limit :make_request,
                limit: 100,
                period: 1.minute

  # Rate limit for class method
  set_rate_limit :bulk_request,
                limit: 10,
                period: 1.hour

  # Advanced usage with all options (instance method)
  set_rate_limit :another_method,
                limit: 10,                       # Maximum calls allowed
                period: 1.hour,                  # Time window for the limit
                by: -> { "client:#{id}" },       # Method call identifier
                store: :memcached,               # Override default store
                on_exceeded: -> {                # Custom error handler
                  # You can handle the error here and return any value (including nil)
                  notify_admin
                  log_exceeded_event
                  nil # Method will return nil
                }

  # Advanced usage with all options (class method)
  set_rate_limit :another_class_method,
                limit: 5,                        # Maximum calls allowed
                period: 1.day,                   # Time window for the limit
                by: -> { "global:#{name}" },     # Method call identifier
                store: :redis,                   # Override default store
                on_exceeded: -> {                # Custom error handler
                  log_exceeded_event
                  "Rate limit exceeded"          # Return custom message
                }

  # Direct rate limit setting
  # You can also set rate limits directly if you have both instance and class methods with the same name
  set_instance_rate_limit :process,             # For instance method
                         limit: 10,
                         period: 1.hour

  set_class_rate_limit :process,                # For class method
                      limit: 5,
                      period: 1.hour
end
```

### Available Options

For both controllers and methods:
- `limit`: (Required) Maximum number of requests/calls allowed
- `period`: (Required) Time period for the limit (in seconds or ActiveSupport::Duration)
- `by`: (Optional) Lambda/Proc to generate unique identifier
  - Default for controllers: `"#{controller.class.name}:#{controller.request.remote_ip}"`
  - Default for instance methods: `"#{self.class.name}##{method_name}:#{respond_to?(:id) ? 'id='+id.to_s : 'object_id='+object_id.to_s}"`
  - Default for class methods: `"#{class.name}.#{method_name}"`
- `store`: (Optional) Override default storage backend (`:redis`, `:memcached`, `:memory`)
- `on_exceeded`: (Optional) Custom handler for rate limit exceeded

Additional options for controllers:
- `as`: (Optional) Custom name for rate limit
- `only`: (Optional) Array of action names to limit
- `except`: (Optional) Array of action names to exclude

### Rate Limit Exceeded Handling

The gem provides different default behaviors for controllers and methods:

1. For controllers (HTTP requests):
   - The `on_exceeded` handler (or default handler) is called
   - By default, returns HTTP 429 with a JSON error message
   - Headers are automatically added with limit information
   - The handler's return value is used (usually render/redirect)

2. For methods:
   - The `on_exceeded` handler (if provided) is called first
   - Then `RailsRateLimit::RateLimitExceeded` exception is raised
   - The event is logged if a logger is configured
   - You should catch the exception to handle the error

### Default error messages

By default, the gem logs the error message to the logger together with your custom `on_exceeded` message.
```ruby
@logger.warn(
  "Rate limit exceeded for #{key}. " \
  "Limit: #{limit} requests per #{period} seconds"
)
# where key for klass is `by` or default unique identifier
# Rate limit exceeded for ReportGenerator#generate:object_id=218520. Limit: 2 requests per 10 seconds
# Rate limit exceeded for Notification#deliver:id=1. Limit: 3 requests per 60 seconds
# Rate limit exceeded for ReportGenerator.generate. Limit: 2 requests per 10 seconds

# where key for controller is `by` or default unique identifier
# Rate limit exceeded for HomeController:127.0.0.1. Limit: 100 requests per 1 minute
```

You can remove it by setting `config.logger = nil` or specify `by` options.

### HTTP Headers

For controller rate limiting, the following headers are automatically added:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Remaining requests in current period
- `X-RateLimit-Reset`: Time when the current period will reset (Unix timestamp)

## Storage Backends

### Memory (Default)
- No additional dependencies
- Perfect for development or single-server setups
- Data is lost on server restart
- Not suitable for distributed systems
- Thread-safe implementation

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kasvit/rails_rate_limit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
