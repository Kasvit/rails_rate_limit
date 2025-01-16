# RailsRateLimit

A flexible and robust rate limiting solution for Rails applications. Supports Redis, Memcached, and Memory stores.

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

### Basic Setup

Create `config/initializers/rails_rate_limit.rb`:

```ruby
RailsRateLimit.configure do |config|
  # Choose storage backend (:redis, :memory, or :memcached)
  config.default_store = :redis
  
  # Configure Redis connection
  config.redis_connection = Redis.new(url: 'redis://localhost:6379/0')
  
  # OR configure Memcached
  config.memcached_connection = Dalli::Client.new('localhost:11211')
  
  # Configure logging
  config.logger = Rails.logger
  
  # Custom default response
  config.default_response = -> {
    render json: {
      error: 'Rate limit exceeded',
      retry_after: response.headers["Retry-After"]
    }, status: :too_many_requests
  }
end
```

### Controller Usage

#### Basic Usage

```ruby
class ApiController < ApplicationController
  include RailsRateLimit::Controller

  # Limit: 100 requests per hour
  controller_rate_limit limit: 100,
                       period: 1.hour,
                       only: [:index, :show]
end
```

#### Advanced Usage

```ruby
class ApiController < ApplicationController
  include RailsRateLimit::Controller

  # Dynamic limit based on user type
  controller_rate_limit limit: -> { current_user&.premium? ? 1000 : 100 },
                       period: 1.hour,
                       by: -> { "user:#{current_user&.id}" },
                       store: :redis,
                       only: [:create, :update]

  # Different limits for different endpoints
  controller_rate_limit limit: 1000,
                       period: 1.day,
                       by: -> { request.remote_ip },
                       store: :memcached,
                       only: :index

  # Custom rate limit exceeded response
  controller_rate_limit limit: 50,
                       period: 1.hour,
                       response: -> {
                         render json: {
                           error: 'Rate limit exceeded',
                           try_again_in: response.headers["Retry-After"]
                         }, status: 429
                       },
                       only: :search
end
```

### Available Options

#### Core Parameters

- `limit`: Number of allowed requests
  - Static number: `limit: 100`
  - Dynamic value: `limit: -> { current_user.rate_limit }`

- `period`: Time window
  - Uses ActiveSupport::Duration
  - Examples: `1.hour`, `30.minutes`, `1.day`

- `by`: Request grouping identifier
  - Default: IP address
  - String: `by: "custom_key"`
  - Dynamic value: `by: -> { "#{request.remote_ip}:#{current_user&.id}" }`

- `store`: Counter storage backend
  - `:redis` - recommended for production
  - `:memcached` - Redis alternative
  - `:memory` - for development/testing

- `response`: Custom rate limit exceeded response
  - Proc executed in controller context
  - Default: returns JSON error with 429 status

#### Additional Options

All other options are passed to `before_action`, for example:
- `only: [:index, :show]`
- `except: [:create, :update]`
- `if: -> { current_user.present? }`
- `unless: -> { Rails.env.development? }`

### HTTP Headers

The gem automatically adds these headers to the response:

- `X-RateLimit-Limit`: Maximum number of requests allowed
- `X-RateLimit-Remaining`: Number of requests remaining
- `X-RateLimit-Reset`: Unix timestamp when the limit resets
- `Retry-After`: Seconds until limit reset (only when exceeded)

### Storage Backends

#### Redis
```ruby
# config/initializers/rails_rate_limit.rb
config.default_store = :redis
config.redis_connection = Redis.new(url: 'redis://localhost:6379/0')

# In controller
controller_rate_limit limit: 100,
                     period: 1.hour,
                     store: :redis
```

#### Memcached
```ruby
# config/initializers/rails_rate_limit.rb
config.default_store = :memcached
config.memcached_connection = Dalli::Client.new('localhost:11211')

# In controller
controller_rate_limit limit: 100,
                     period: 1.hour,
                     store: :memcached
```

#### Memory
```ruby
# config/initializers/rails_rate_limit.rb
config.default_store = :memory

# In controller
controller_rate_limit limit: 100,
                     period: 1.hour,
                     store: :memory
```

### Logging and Monitoring

```ruby
RailsRateLimit.configure do |config|
  # Configure logger
  config.logger = Logger.new('log/rate_limit.log')
end
```

Example log when limit is exceeded:
```
[RailsRateLimit] Rate limit exceeded for key: user:123, limit: 100, period: 3600
```

## Development

After checking out the repo:

1. Install dependencies:
```bash
$ bin/setup
```

2. Run the tests:
```bash
$ bundle exec rspec
```

3. Start a console for experiments:
```bash
$ bin/console
```

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
