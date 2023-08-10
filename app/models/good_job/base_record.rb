# frozen_string_literal: true

module GoodJob
  # Base ActiveRecord class that all GoodJob models inherit from.
  # Parent class can be configured with +GoodJob.active_record_parent_class+.
  # @!parse
  #   class BaseRecord < ActiveRecord::Base; end
  class BaseRecord < ActiveRecordParentClass
    self.abstract_class = true

    def self.migration_pending_warning!
      GoodJob.deprecator.warn(<<~DEPRECATION)
        GoodJob has pending database migrations. To create the migration files, run:
            rails generate good_job:update
        To apply the migration files, run:
            rails db:migrate
      DEPRECATION
      nil
    end

    # Checks for whether the schema is up to date.
    # Can be overriden by child class.
    # @return [Boolean]
    def self.migrated?
      return true if table_exists?

      migration_pending_warning!
      false
    end

    # Runs the block with self.logger silenced.
    # If self.logger is nil, simply runs the block.
    def self.with_logger_silenced(&block)
      # Assign to a local variable, just in case it's modified in another thread concurrently
      logger = self.logger
      if logger
        logger.silence(&block)
      else
        block.call
      end
    end

    ActiveSupport.run_load_hooks(:good_job_base_record, self)
  end
end
