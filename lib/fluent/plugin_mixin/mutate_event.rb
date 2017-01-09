module Fluent
  module PluginMixin
    class MutateEvent < SimpleDelegator
      def initialize(record, expand_nesting: true)
        super(record)
        @record = record
        @event_time = nil
        @event_tag  = nil
        @expand_nesting = expand_nesting
      end

      unless method_defined?(:log)
        define_method("log") { $log }
      end

      attr_accessor :event_time
      attr_accessor :event_tag

      def to_record
        @record
      end

      def dig(*keys)
        item = @record

        keys.each do |key|
          break if item.nil?
          case item.class.to_s
            when "Hash" then item = item[key]
            when "Array" then item = item[Integer(key)]
            else item = nil
          end
        end

        item
      end

      def prune
        delete_proc = proc do |*args|
          if args.length == 1 then v = args[0] else v = args[1] end
          v.delete_if(&delete_proc) if v.respond_to?(:delete_if)
          v.nil? || v.respond_to?(:empty?) && v.empty?
        end

        @record.delete_if(&delete_proc)
      end

      def get(key_or_path, &block)
        item = dig(*expand_key(key_or_path))
        block_given? ? yield(item) : item
      end

      def parent(key_or_path, &block)
        path = expand_key(key_or_path)
        child = path.pop

        item = dig(*path)
        block_given? ? yield(item, child) : item
      end

      def set(key_or_path, value)
        path = expand_key(key_or_path)
        child = path.pop

        item = @record
        path.each do |key|
          item = item[key] ||= {}
        end
        item[child] = value
      end

      def remove(key_or_path)
        path = expand_key(key_or_path)
        child = path.pop

        parent(key_or_path) do |item, child|
          item.delete(child) unless item.nil?
        end
      end

      def include?(key_or_path)
        !get(key_or_path).nil?
      end

      protected

      def expand_key(key_or_path)
        @expand_nesting ? key_or_path.split(".") : [key_or_path]
      end
    end
  end
end
