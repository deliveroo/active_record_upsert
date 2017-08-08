module ActiveRecordUpsert
  module ActiveRecord
    module PersistenceExtensions

      def upsert!(attributes: nil, where: [], validate: true)
        raise ::ActiveRecord::ReadOnlyRecord, "#{self.class} is marked as readonly" if readonly?
        raise ::ActiveRecord::RecordSavedError, "Can't upsert a record that has already been saved" if persisted?
        validate == false || perform_validations || raise_validation_error
        values = run_callbacks(:save) {
          run_callbacks(:create) {
            attributes ||= changed
            attributes = attributes.map(&:to_s) + ['created_at', 'updated_at']
            _upsert_record(attributes, where)
          }
        }
        assign_attributes(values.first.to_h)
        self
      end

      def upsert(*args)
        upsert!(*args)
      rescue ::ActiveRecord::RecordInvalid
        false
      end


      def _upsert_record(attribute_names = changed, wheres = [])
        attributes_values = arel_attributes_with_values_for_create(attribute_names)
        values = self.class.unscoped.upsert(attributes_values, wheres)
        @new_record = false
        values
      end

      module ClassMethods
        def upsert!(attributes, where: [], &block)
          if attributes.is_a?(Array)
            attributes.collect { |hash| upsert(hash, &block) }
          else
            new(attributes, &block).upsert!(
              attributes: attributes.keys, where: where, validate: true
            )
          end
        end

        def upsert(*args)
          upsert!(*args)
        rescue ::ActiveRecord::RecordInvalid
          false
        end

        def upsert_keys(*keys)
          return @_upsert_keys if keys.empty?
          keys = keys.first if keys.size == 1 # support single string/symbol, multiple string/symbols, and array
          @_upsert_keys = Array(keys).map(&:to_s)
        end
      end
    end
  end
end
