require 'active_support/basic_object'

module RedmineBetterGanttChart
  module ActiveRecord
    class WithoutCallbacks < ActiveSupport::BasicObject
      def initialize(target, types)
        @target = target
        @types  = types
      end

      def respond_to?(method, include_private = false)
        @target.respond_to?(method, include_private)
      end

      def method_missing(method, *args, &block)
        @target.skip_callbacks(*@types) do
          @target.send(method, *args, &block)
        end
      end
    end

    module CallbackExtensionsForRails3
      extend ActiveSupport::Concern

      module ClassMethods
        def without_callbacks(*types)
          callback_options={}
          callback_hash= Hash[callbacks.map{|callback|
              chain = send("_#{callback}_callbacks")
              options = Hash[chain.map{|c| [c.filter,{:options=>c.options,:per_key=>c.per_key}]}]
              callback_options.reverse_merge!(options)
              chain_hash=Hash[chain.map{|c| [c.kind, chain.collect{|ch| ch.filter if ch.kind==c.kind}.compact]}]
              [callback,chain_hash]
            }
          ]
          callback_hash.each {|callback,filters|
            filters.each{|filter,methods|
              skip_callback(callback, filter, *methods)
            }
            name = :"_run_#{type}_callbacks"
            alias_method(:"_deactivated_#{name}", name)
          callback_hash.each {|callback,filters|
            filters.each{|filter,methods|
              methods.each{|method|
                set_callback(callback, filter, method, callback_options[method])
              }
            }
            name = :"_run_#{type}_callbacks"
            alias_method(name, :"_deactivated_#{name}")
            undef_method(:"_deactivated_#{name}")
          end
            :destroy
        end
      end
    end
  end
end
