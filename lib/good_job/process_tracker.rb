# frozen_string_literal: true

module GoodJob # :nodoc:
  class ProcessTracker
    attr_reader :record, :locks, :advisory_locks

    # @!attribute [r] instances
    #   @!scope class
    #   List of all instantiated ProcessTrackers in the current process.
    #   @return [Array<GoodJob::ProcessTracker>, nil]
    cattr_reader :instances, default: Concurrent::Array.new, instance_reader: false

    def initialize(executor: Concurrent.global_io_executor)
      @executor = executor
      @mutex = Mutex.new
      @locks = 0
      @advisory_locks = 0
      @ruby_pid = ::Process.pid
      @record_id = SecureRandom.uuid
      @record = nil
      @refresh_task = nil

      self.class.instances << self
    end

    def id_for_lock
      synchronize do
        next if @locks.zero?

        reset_on_fork
        Rails.application.executor.wrap do
          if @record
            @record.refresh_if_stale
          else
            @record = GoodJob::Process.create_record(id: @record_id)
            create_refresh_task
          end
          @record&.id
        end
      end
    end

    # Registers the current process in the database
    # @return [GoodJob::Process]
    def register(with_advisory_lock: false)
      synchronize do
        if with_advisory_lock
          Rails.application.executor.wrap do
            if @record
              @record.update(lock_type: GoodJob::Process::LOCK_TYPE_ADVISORY) if @record.advisory_lock
            else
              @record = GoodJob::Process.create_record(id: @record_id, with_advisory_lock: true)
              create_refresh_task
            end
          end
          @advisory_locks += 1
        end

        @locks += 1
      end
      return unless block_given?

      begin
        yield
      ensure
        unregister(with_advisory_lock: with_advisory_lock)
      end
    end

    def unregister(with_advisory_lock: false)
      synchronize do
        Rails.application.executor.wrap do
          if with_advisory_lock && @record && @advisory_locks.positive?
            @record.update(lock_type: nil) if @record.advisory_unlock
            @advisory_locks -= 1
          end

          if @locks == 1 && @record
            @record.destroy
            @record = nil
          end
        end

        cancel_refresh_task if @locks == 1
        @locks -= 1 unless @locks.zero?
      end
    end

    def task_observer(_time, _output, thread_error)
      GoodJob._on_thread_error(thread_error) if thread_error && !thread_error.is_a?(Concurrent::CancelledOperationError)
    end

    private

    def create_refresh_task
      return if @refresh_task

      @refresh_task = Concurrent::ScheduledTask.new(GoodJob::Process::STALE_INTERVAL, executor: @executor) do
        synchronize do
          create_refresh_task
          @record&.refresh_if_stale
        end
      end
      @refresh_task.add_observer(self, :task_observer)
      @refresh_task.execute
    end

    def cancel_refresh_task
      @refresh_task = nil if @refresh_task && (@refresh_task.cancel || @refresh_task.cancelled?)
    end

    def synchronize(&block)
      if @mutex.owned?
        yield
      else
        @mutex.synchronize(&block)
      end
    end

    def reset_on_fork
      return if @ruby_pid == ::Process.pid

      @ruby_pid = ::Process.pid
      @record_id = SecureRandom.uuid
      @record = nil
    end
  end
end
