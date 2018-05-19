require 'unscoped_associations/version'

module UnscopedAssociations
  def self.included(base)
    class << base
      prepend ClassMethods
    end
  end

  module ClassMethods
    def belongs_to(name, scope = nil, options = {})
      super(*prebuild_unscoped!(:belongs_to, name, scope, options))
    end

    def has_many(name, scope = nil, options = {}, &extension)
      super(*prebuild_unscoped!(:has_many, name, scope, options), &extension)
    end

    def has_one(name, scope = nil, options = {})
      super(*prebuild_unscoped!(:has_one, name, scope, options))
    end

    private

    def prebuild_unscoped!(assoc_type, assoc_name, scope = nil, options = {})
      if scope.is_a?(Hash)
        options = scope
        scope   = nil
      end

      if options.delete(:unscoped)
        add_unscoped_association(assoc_type, assoc_name)
      end

      [assoc_name, scope, options].compact
    end

    def add_unscoped_association(association_type, association_name)
      define_method(association_name) do |*args|
        force_reload = args[0]
        if force_reload == nil && ActiveRecord::VERSION::MAJOR >= 5
          if instance_variable_get("@_cache_#{association_name}")
            instance_variable_get("@_cache_#{association_name}")
          else
            instance_variable_set(
              "@_cache_#{association_name}",
              association(association_name).klass.unscoped do
                association_type == :has_many ? super().reload : public_send("reload_#{association_name}")
              end
            )
          end
        else
          if !force_reload && instance_variable_get("@_cache_#{association_name}")
            instance_variable_get("@_cache_#{association_name}")
          else
            instance_variable_set(
              "@_cache_#{association_name}",
              association(association_name).klass.unscoped { super(true) }
            )
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, UnscopedAssociations)
