# frozen_string_literal: true

require "active_record"
require "active_support/core_ext"
require "erb"
require "yaml"

class TestModel < ActiveRecord::Base; end

module ConfigureDatabase
  def configure_database(db_config_path)
    # Load Database spec from config/database.yml
    source = ERB.new(File.read(db_config_path)).result
    spec   = YAML.safe_load(source, aliases: true) || {}

    ActiveRecord::Base.configurations = spec.stringify_keys
    ActiveRecord::Tasks::DatabaseTasks.root = File.expand_path("../fixtures", __dir__)
    ActiveRecord::Tasks::DatabaseTasks.create(
      ActiveRecord::Base.configurations.configurations.first
    )
    ActiveRecord::Base.establish_connection(:test)
  end

  def create_test_model_table
    ActiveRecord::Base.connection.drop_table(:test_models, if_exists: true)
    ActiveRecord::Base.connection.create_table(:test_models)
  end
end
