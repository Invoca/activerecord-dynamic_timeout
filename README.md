# activerecord-dynamic_timeout
Dynamic query timeouts within ActiveRecord!

## Installation

Add this line to your application's Gemfile:
```ruby
gem 'activerecord-dynamic_timeout', require: 'active_record/dynamic_timeout/railtie'
```

### Non-Rails Applications
If you are using this gem in a non-rails application, you will need run the initializer manually.
```ruby
require "active_record/dynamic_timeout"
ActiveRecord::DynamicTimeout::Initializer.initialize!
```

## Usage
    
```ruby
class MyModel < ActiveRecord::Base
  # Model code...
end

MyModel.with_timeout(5) do
  MyModel.find(1)
end
```

## Supported Adapters
* mysql2
* trilogy - ActiveRecord versions 7.1+
* postgresql
* sqlite3

See [OtherAdapters](#other-adapters) on how to add support for other adapters.

### Mysql2
Timeouts are set using the client read_timeout and write_timeout attributes on the client. At the moment this is a bit of a hack as the mysql2 gem doesn't provide
a clean way to set these attributes (via a public method).

A Pull Request has been open for over 6 years to add per-query read_timeouts: https://github.com/brianmario/mysql2/pull/955

No queries are executed to set the timeouts.

### Trilogy
Timeouts are set via the client read_timeout and write_timeout attributes on the clients. No queries are executed to set the timeouts.

### Postgresql
Timeouts are set via setting the session variable via the following query `SET SESSION statement_timeout TO <timeout>`.

See more information at https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-STATEMENT-TIMEOUT

**Note** - statement_timeout is in milliseconds. Pass the timeout as an integer in milliseconds
```ruby
AcitveRecord::Base.with_timeout(5000) do
  # Run queries that each need to return within 5 seconds
end
```
**Note** - Because this executes a query to set the timeout, we will lazily set and reset the timeout on the connection. This is done to reduce
the number of queries run.

### Sqlite3
Timeouts are set via setting the busy_timeout PRAGMA attribute on the connection.

See more information at https://www.sqlite.org/pragma.html#pragma_busy_timeout

Note that `busy_timeout` only will trigger if a table is locked for over the timeout. This does not work for SELECT statements.

**Note** - Because this executes a query to set the timeout, we will lazily set and reset the timeout on the connection. This is done to reduce
the number of queries run.

### Other Adapters
If you would like to add support for a different adapter, add the following code to the adapter:
1. `#supports_dynamic_timeouts?` - Must return true
2. `#set_connection_timeout(raw_connection, timeout)` - Set the timeout on the connection
3. `#reset_connection_timeout(raw_connection)` - Reset the timeout on the connection
4. `#timeout_set_client_side?` - Used to decide if the timeout should be set lazily (and reset) or not

```ruby
module MyAdapterDynamicTimeouts
  # @return [Boolean]
  def supports_dynamic_timeouts?
    true # Must return true.
  end

  # @param raw_connection [Object] The raw connection object of the adapter
  # @param timeout [Integer] The timeout passed in by the user
  def set_connection_timeout(raw_connection, timeout)
    # Set the timeout on the connection
  end

  # @param raw_connection [Object] The raw connection object of the adapter
  def reset_connection_timeout(raw_connection)
    # Reset the timeout on the connection, to the default value or the value set in the database configuration file.
  end

  # @return [Boolean]
  def timeout_set_client_side?
    false
    # Return true if the timeout does not require a query to be executed in order to set the timeout
    # Return false if the timeout requires a query to be executed in order to set the timeout. When false, the timeout will be set lazily, only when necessary.
  end
end

class MyAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
  include MyAdapterDynamicTimeouts
  # ...
end
```

## Contributing
Bug reports and pull requests are welcome on GitHub.
