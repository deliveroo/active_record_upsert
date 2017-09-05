[![Gem Version](https://badge.fury.io/rb/active_record_upsert.svg)](https://badge.fury.io/rb/active_record_upsert)
[![Build Status](https://travis-ci.org/jesjos/active_record_upsert.svg?branch=master)](https://travis-ci.org/jesjos/active_record_upsert)
[![Code Climate](https://codeclimate.com/github/jesjos/active_record_upsert/badges/gpa.svg)](https://codeclimate.com/github/jesjos/active_record_upsert)
[![Dependency Status](https://gemnasium.com/badges/github.com/jesjos/active_record_upsert.svg)](https://gemnasium.com/github.com/jesjos/active_record_upsert)

# ActiveRecordUpsert

Real upsert for PostgreSQL 9.5+ and Rails 5 / ActiveRecord 5. Uses [ON CONFLICT DO UPDATE](http://www.postgresql.org/docs/9.5/static/sql-insert.html).

## Main points

- Does upsert on a single record using `ON CONFLICT DO UPDATE`
- Updates timestamps as you would expect in ActiveRecord
- For partial upserts, loads any existing data from the database

## Prerequisites

- PostgreSQL 9.5+
- ActiveRecord ~> 5
- For MRI: pg

- For JRuby: No support

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'active_record_upsert'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record_upsert

## Usage

Use `ActiveRecord.upsert` or `ActiveRecord#upsert`. *ActiveRecordUpsert* respects timestamps.

```ruby
class MyRecord < ActiveRecord::Base
end

MyRecord.create(name: 'foo', wisdom: 1)
# => #<MyRecord id: 1, name: "foo", created_at: "2016-02-20 14:15:55", updated_at: "2016-02-20 14:15:55", wisdom: 1>

MyRecord.upsert(id: 1, wisdom: 3)
# => #<MyRecord id: 1, name: "foo", created_at: "2016-02-20 14:15:55", updated_at: "2016-02-20 14:18:15", wisdom: 3>

r = MyRecord.new(id: 1)
r.name = 'bar'
r.upsert
# => #<MyRecord id: 1, name: "bar", created_at: "2016-02-20 14:15:55", updated_at: "2016-02-20 14:18:49", wisdom: 3>
```

If you need to specify a condition for the update, pass it as an Arel query:

```ruby
MyRecord.upsert({id: 1, wisdom: 3}, arel_condition: MyRecord.arel_table[:updated_at].lt(1.day.ago))
```

The instance method `#upsert` can also take keyword arguments to specify a condition, or to limit which attributes to upsert
(by default, all `changed` attributes will be passed to the upsert):

```ruby
r = MyRecord.new(id: 1)
r.name = 'bar'
r.color = 'blue'
r.upsert(attributes: [:name], arel_condition: MyRecord.arel_table[:updated_at].lt(1.day.ago))
# will only update :name, and only if the record is older than 1 day;
# but if the record does not exist, will insert with both :name and :colors
```

Upsert will perform validation on the object, and return false if it is not valid. To skip validation, pass `validate: false`:
```ruby
MyRecord.upsert({id: 1, wisdom: 3}, validate: false)
```

If you want validations to raise `ActiveRecord::RecordInvalid`, use `upsert!`:
```ruby
MyRecord.upsert!(id: 1, wisdom: 3)
```

Or using the instance method:
```ruby
r = MyRecord.new(id: 1, name: 'bar')
r.upsert!
```

It's possible to specify which columns should be used for the conflict clause. **These must comprise a unique index in Postgres.**

```ruby
class Vehicle < ActiveRecord::Base
  upsert_keys [:make, :name]
end

Vehicle.upsert(make: 'Ford', name: 'F-150', doors: 4)
# => #<Vehicle id: 1, make: 'Ford', name: 'Focus', doors: 2>

Vehicle.create(make: 'Ford', name: 'Focus', doors: 4)
# => #<Vehicle id: 2, make: 'Ford', name: 'Focus', doors: 4>

r = Vehicle.new(make: 'Ford', name: 'F-150')
r.doors = 2
r.upsert
# => #<Vehicle id: 1, make: 'Ford', name: 'Focus', doors: 2>
```

## Tests

Make sure to have an upsert_test database:

```shell
bin/run_rails.sh db:create db:migrate DATABASE_URL=postgresql://localhost/upsert_test
```

Then run `rspec`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jesjos/active_record_upsert.

## Contributors

- Jesper Josefsson
- Jens Nockert
- Olle Jonsson
- Simon Dahlbacka
- Paul Hoffer
- Ivan ([@me](https://github.com/me))
- Leon Miller-Out ([@sbleon](https://github.com/sbleon))
