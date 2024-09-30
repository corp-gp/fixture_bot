# `fixture_bot`

Improve the performance of your tests, as factories generate and insert data into the database every time, it can be slow. See [benchmarks](#Benchmarks).

Problems using [Rails fixtures](https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html):

- No data validation
- Long loading of fixtures (for one or all tests - equally long)
- YML format (no reuse code)
- heavy support for fixtures and factories together

### Installation

```ruby
group :test do
  gem "factory_bot"
  gem "fixture_bot", require: false
end
```

### Usage

To define your fixture in factories, use the `preload` method

```ruby
FactoryBot.define do
  factory :user do
    name "John Doe"
    sequence(:email) {|n| "john#{n}@example.org" }
  end
  
  preload(:users) do
    fixture_with_id(:first) { create(:user, id: 1) }
    fixture(:john) { create(:user) }
    fixture(:with_gmail) { create(:user, email: "email@gmail.com") }
  end
end
```

```ruby
FactoryBot.define do
  factory :projects do
    name "My Project"
    user { users(:with_gmail) }
  end

  preload(:users) do
    fixture(:myapp) { create(:project, user: users(:john)) }
  end
end
```


### RSpec usage

```ruby
require "spec_helper"

describe User do
  let(:user) { users(:john) }

  it "returns john's record" do
    expect(users(:john)).to be_a User
  end

  it "returns myapp's record" do
    expect(projects(:myapp).user).to eq users(:john)
  end

  it "each call fixture return new object" do
    expect(user.object_id).not_to eq users(:john).object_id
  end
end
```

### RSpec Setup

On your `spec/support/factory_bot.rb` file

```ruby
require "fixture_bot" # the order is important, it must be before loaded factories
require "factory_bot_rails"

FactoryBot::SyntaxRunner.class_eval do
  include RSpec::Mocks::ExampleMethods
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

### Minitest Setup

On your `test/test_helper.rb` file, make sure that transaction fixtures are
enabled. Here's what your file may look like

```ruby
# First, load fixture_bot
require "fixture_bot"
FixtureBot.minitest
```

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "returns john's record" do
    assert_instance_of User, users(:john)
  end

  test "returns myapp's record" do
    assert_equal users(:john), projects(:myapp).user
  end
end
```

## Callbacks
```ruby
FixtureBot.after_load_fixtures do
  # code uses fixtures
end
```

## Benchmarks
#### factories vs fixtures

simple model with 10 fields
```ruby
Benchmark.ips do |x|
  x.report("fixture") { brands(:lux) }.   # fixture:     4666.2 i/s
  x.report("factory") { create(:brand) }  # factory:     1077.8 i/s - 4.33x  slower
  x.compare!
end
```

user model with 40+ fields, 1 association
```ruby
Benchmark.ips do |x|
  x.report("fixture") { users(:with_post_index)} # fixture:     3395.4 i/s
  x.report("factory") { create(:user) }          # factory:      159.6 i/s - 21.27x  slower
  x.compare!
end
```

product model with 40+ fields, 5+ associations
```ruby
Benchmark.ips do |x|
  x.report("fixture") { products(:available) }         # fixture:     3564.3 i/s
  x.report("factory") { create(:product, :available) } # factory:       67.7 i/s - 52.68x  slower
  x.compare!
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
