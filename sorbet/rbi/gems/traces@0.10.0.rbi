# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `traces` gem.
# Please instead update this file by running `bin/tapioca gem traces`.

# source://traces//lib/traces/backend.rb#6
module Traces
  class << self
    # Extend the specified class in order to emit traces.
    #
    # source://traces//lib/traces/provider.rb#59
    def Provider(klass, &block); end

    # @return [Boolean]
    #
    # source://traces//lib/traces/provider.rb#10
    def enabled?; end

    # Require a specific trace backend.
    #
    # source://traces//lib/traces/backend.rb#8
    def require_backend(env = T.unsafe(nil)); end
  end
end

# source://traces//lib/traces/provider.rb#24
module Traces::Deprecated
  # source://traces//lib/traces/provider.rb#25
  def trace(*_arg0, **_arg1, &_arg2); end

  # source://traces//lib/traces/provider.rb#30
  def trace_context; end

  # source://traces//lib/traces/provider.rb#35
  def trace_context=(value); end
end

# source://traces//lib/traces/provider.rb#14
module Traces::Provider; end

# source://traces//lib/traces/provider.rb#17
module Traces::Singleton
  # A module which contains tracing specific wrappers.
  #
  # source://traces//lib/traces/provider.rb#19
  def traces_provider; end
end
