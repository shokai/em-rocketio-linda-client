module EM
  module RocketIO
    module Linda
      class Client
        class Error < StandardError
        end

        class TupleInfo < Hashie::Mash
        end

        include EventEmitter
        attr_reader :io, :tuplespace
        def initialize(io_or_url)
          if io_or_url.kind_of? String and io_or_url =~ /^https*:\/\/.+$/
            @io = ::EM::RocketIO::Client.new(io_or_url).connect
          elsif io_or_url.kind_of? ::EM::RocketIO::Client
            @io = io_or_url
          else
            raise ArgumentError, "argument must be URL or EM::RocketIO::Client"
          end
          @tuplespace = Hash.new{|h,k|
            h[k] = EM::RocketIO::Linda::Client::TupleSpace.new(k, self)
          }
        end

        class TupleSpace
          attr_reader :name, :linda
          def initialize(name, linda)
            @name = name
            @linda = linda
          end

          def write(tuple, opts={})
            unless [Hash, Array].include? tuple.class
              raise ArgumentError, "tuple must be Array or Hash"
            end
            @linda.io.push "__linda_write", [@name, tuple, opts]
          end

          def read(tuple, &block)
            unless [Hash, Array].include? tuple.class
              raise ArgumentError, "tuple must be Array or Hash"
            end
            callback_id = make_callback_id
            if block_given?
              @linda.io.once "__linda_read_callback_#{callback_id}" do |data|
                block.call(data['tuple'], TupleInfo.new(data['info']))
              end
              @linda.io.push "__linda_read", [@name, tuple, callback_id]
              return
            end
            result_tuple = nil
            @linda.io.once "__linda_read_callback_#{callback_id}" do |data|
              result_tuple = data['tuple']
            end
            @linda.io.push "__linda_read", [@name, tuple, callback_id]
            while !result_tuple do
              sleep 0.1
            end
            return result_tuple
          end

          def take(tuple, &block)
            unless [Hash, Array].include? tuple.class
              raise ArgumentError, "tuple must be Array or Hash"
            end
            callback_id = make_callback_id
            if block_given?
              @linda.io.once "__linda_take_callback_#{callback_id}" do |data|
                block.call data['tuple'], TupleInfo.new(data['info'])
              end
              @linda.io.push "__linda_take", [@name, tuple, callback_id]
              return
            end
            result_tuple = nil
            @linda.io.once "__linda_take_callback_#{callback_id}" do |data|
              result_tuple = data['tuple']
            end
            @linda.io.push "__linda_take", [@name, tuple, callback_id]
            while !result_tuple do
              sleep 0.1
            end
            return result_tuple
          end

          def watch(tuple, &block)
            unless [Hash, Array].include? tuple.class
              raise ArgumentError, "tuple must be Array or Hash"
            end
            return unless block_given?
            callback_id = make_callback_id
            @linda.io.on "__linda_watch_callback_#{callback_id}" do |data|
              block.call data['tuple'], TupleInfo.new(data['info'])
            end
            @linda.io.push "__linda_watch", [@name, tuple, callback_id]
          end

          def list(tuple, &block)
            unless [Hash, Array].include? tuple.class
              raise ArgumentError, "tuple must be Array or Hash"
            end
            callback_id = make_callback_id
            if block_given?
              @linda.io.once "__linda_list_callback_#{callback_id}" do |list|
                block.call list
              end
              @linda.io.push "__linda_list", [@name, tuple, callback_id]
              return
            end
            results = nil
            @linda.io.once "__linda_list_callback_#{callback_id}" do |list|
              results = list
            end
            @linda.io.push "__linda_list", [@name, tuple, callback_id]
            while results == nil do
              sleep 0.1
            end
            return results
          end

          private
          def make_callback_id
            "#{Time.now.to_i}#{Time.now.usec}_#{rand(1000000).to_i}"
          end

        end

      end
    end
  end
end
