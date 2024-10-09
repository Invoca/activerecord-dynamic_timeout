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
To use this gem, you can set a timeout for a block of code that runs queries using ActiveRecord.
Within the block, if a query takes longer than the timeout value (in seconds), an `ActiveRecord::QueryAborted` error (or a subclass of it) will be raised.

#### Example
```ruby
class MyModel < ActiveRecord::Base
  # Model code...
end

MyModel.all # A long query that takes over 5 seconds
# => ActiveRecord::Relation<MyModel>...

# Set a timeout for all queries run within the block
MyModel.with_timeout(5.seconds) do
  MyModel.all # A long running query that takes over 5 seconds
end
# => Raises ActiveRecord::QueryAborted error (or a subclass of it) after 5 seconds.
```

## Supported Adapters
* mysql2
* trilogy - ActiveRecord versions 7.1+
* postgresql
* sqlite3 (version >= 2.0) - Note - ActiveRecord < 7.1 does not support sqlite3 >= 2.0

See [OtherAdapters](#other-adapters) on how to add support for other adapters.

### Mysql2
Timeouts are set using the client read_timeout and write_timeout attributes on the client. At the moment this is a bit of a hack as the mysql2 gem doesn't provide
a clean way to set these attributes (via a public method).

A Pull Request has been open for over 6 years to add per-query read_timeouts: https://github.com/brianmario/mysql2/pull/955

No queries are executed to set the timeouts.

#### Warning on Raw Inserts and Updates
If you are using raw inserts or updates, ensure you wrap them in a transaction. If you do not, the timeout will still occur but the query on the server side will still continue.
If you are using normal ActiveRecord methods (e.g. `MyModel.create`, `MyModel.update`, etc.), you do not need to worry about this because these run the queries within a transaction already.

```ruby
### Bad!!!
MyModel.count
# => 0
MyModel.with_timeout(1.seconds) do
  MyModel.connection.execute("INSERT INTO my_models SELECT SLEEP(2)") # This will take longer than 1 second and cause a timeout.
end
# Wait ~1-2 seconds...
MyModel.count
# => 1 # The query still completed on the server side even though the client has timed out.

### Good
# Wrap the raw query in a transaction
# This will cause the query to be rolled back if the timeout occurs.
MyModel.with_timeout(1.seconds) do
  MyModel.transaction do
    MyModel.connection.execute("INSERT INTO my_models SELECT SLEEP(2)") # This will take longer than 1 second and cause a timeout.
  end
end
```

### Trilogy
Timeouts are set via the client read_timeout and write_timeout attributes on the clients. No queries are executed to set the timeouts.

#### Warning on Raw Inserts and Updates (Trilogy)
See [this section](#warning-on-raw-inserts-and-updates) for more information.

### Postgresql
Timeouts are set via setting the session variable via the following query `SET SESSION statement_timeout TO <timeout>`.

See more information at https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-STATEMENT-TIMEOUT

**Note** - Because this executes a query to set the timeout, we will lazily set and reset the timeout on the connection. This is done to reduce
the number of queries run.

### Sqlite3
Timeouts are set via the `Sqlite3::Database#statement_timeout=` method. See more information at https://www.rubydoc.info/gems/sqlite3/SQLite3/Database:statement_timeout=

Under the hood, this sets a progress_handler that will check every 1000 virtual machine instructions if the timeout has been exceeded. If it has,
it will interrupt the query and raise out.

More information about Sqlite Progress Handlers: https://www.sqlite.org/draft/c3ref/progress_handler.html

More information about Sqlite interrupt: https://www.sqlite.org/c3ref/interrupt.html

**Note** - Because this executes a query to set the timeout, we will lazily set and reset the timeout on the connection. This is done to reduce
the number of queries run.

### Other Adapters
If you would like to add support for a different adapter, add the following code to the adapter:
1. `#supports_dynamic_timeouts?` - Must return true
2. `#set_connection_timeout(raw_connection, timeout)` - Set the timeout on the connection
3. `#reset_connection_timeout(raw_connection)` - Reset the timeout on the connection
4. `#timeout_set_client_side?` - Used to decide if the timeout should be set lazily (and reset) or not

```ruby
class MyAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
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
  
  # Adapter code...
end
```

## Contributing
Bug reports and pull requests are welcome on GitHub.
