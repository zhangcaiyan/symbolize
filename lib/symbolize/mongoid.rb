require 'active_support/concern'
require 'active_support/core_ext/hash/keys'

module Mongoid
  module Symbolize
    extend ActiveSupport::Concern

    # Symbolize Mongoid attributes. Add:
    #   symbolize :attr_name
    # to your model class, to make an attribute return symbols instead of
    # string values. Setting such an attribute will accept symbols as well
    # as strings.
    #
    # There's no need for 'field :attr_name', symbolize will do it.
    #
    # Example:
    #   class User
    #     include Mongoid::Document
    #     symbolize :gender, :in => [:female, :male]
    #     symbolize :so, :in => {
    #       :linux   => "Linux",
    #       :mac     => "Mac OS X"
    #     }
    #     symbolize :gui, , :in => [:gnome, :kde, :xfce], :allow_blank => true
    #     symbolize :browser, :in => [:firefox, :opera], :i18n => false
    #   end
    #
    # It will automattically lookup for i18n:
    #
    # models:
    #   symbolizes:
    #     user:
    #       gender:
    #         female: Girl
    #         male: Boy
    #
    # You can skip i18n lookup with :i18n => false
    #   symbolize :gender, :in => [:female, :male], :i18n => false
    #
    # Its possible to use boolean fields also.
    #   symbolize :switch, :in => [true, false]
    #
    #   ...
    #     switch:
    #       "true": On
    #       "false": Off
    #       "nil": Unknown
    #
    module ClassMethods
      # Specifies that values of the given attributes should be returned
      # as symbols. The table column should be created of type string.

      def symbolize(*attr_names) # rubocop:disable Metrics/AbcSize
        configuration = attr_names.extract_options!
        configuration.assert_valid_keys(:in, :within, :i18n, :scopes, :methods, :capitalize, :validate, :default, :allow_blank, :allow_nil, :type)

        enum           = configuration[:in] || configuration[:within]
        i18n           = configuration[:i18n]
        i18n           = enum && !enum.is_a?(Hash) if i18n.nil?
        scopes         = configuration[:scopes]
        methods        = configuration[:methods]
        capitalize     = configuration[:capitalize]
        validation     = configuration[:validate] != false
        default_option = configuration[:default]

        field_type     = configuration[:type] || Symbol
        enum           = [true, false] if [Boolean, ::Boolean].include?(field_type)

        attr_names.each do |attr_name|

          if enum # Enumerators
            enum_hash = \
            if enum.is_a?(Hash)
              enum
            else # Maps [:a, :b, :c] -> {a: 'A', ...
              enum.each_with_object({}) do |e, a|
                a.store(e.respond_to?(:to_sym) ? e.to_sym : e,
                        capitalize ? e.to_s.capitalize : e.to_s)
              end
            end

            #
            # Creates Mongoid's 'field :name, type: type, :default'
            #
            { :type => field_type }.tap do |field_opts|
              field_opts.merge!(:default => default_option) if default_option
              field attr_name, field_opts
            end

            #
            # Creates FIELD_VALUES constants
            #
            values_name = "#{attr_name}_values"
            values_const_name = values_name.upcase
            # Get the values of :in
            const_set values_const_name, enum_hash unless const_defined? values_const_name

            #
            # Define methods
            #
            ["get_#{values_name}", "#{attr_name}_enum"].each do |enum_method_name|
              define_singleton_method(enum_method_name) do
                if i18n
                  enum_hash.each_key.map do |symbol|
                    [i18n_translation_for(attr_name, symbol), symbol]
                  end
                else
                  enum_hash.map(&:reverse)
                end
              end
            end

            if methods
              enum_hash.each_key do |key|
                define_method("#{key}?") do
                  send(attr_name) == key.to_sym
                end
              end
            end

            if scopes
              if scopes == :shallow
                enum_hash.each_key do |name|
                  next unless name.respond_to?(:to_sym)
                  scope name, -> { where(attr_name => name) }
                end
              else # scoped scopes
                scope attr_name, ->(val) { where(attr_name => val) }
              end
            end

            if validation
              validates(*attr_names,
                        configuration.slice(:allow_nil, :allow_blank)
                          .merge(:inclusion => { :in => enum_hash.keys }))
            end
          end

          #
          # Creates <attribute>_text helper, human text for attribute.
          #
          define_method("#{attr_name}_text") do
            if i18n
              read_i18n_attribute(attr_name)
            else
              attr_value = send(attr_name)
              if enum
                enum_hash[attr_value]
              else
                attr_value.to_s
              end
            end
          end

          def i18n_translation_for(attr_name, attr_value)
            I18n.translate("mongoid.symbolizes.#{model_name.to_s.underscore}.#{attr_name}.#{attr_value}")
          end
        end
      end
    end # ClassMethods

    # Return an attribute's i18n
    def read_i18n_attribute(attr_name)
      t = self.class.i18n_translation_for(attr_name, read_attribute(attr_name))
      t.is_a?(Hash) ? nil : t
    end
  end # Symbolize
end # Mongoid

# Symbolize::Mongoid = Mongoid::Symbolize
