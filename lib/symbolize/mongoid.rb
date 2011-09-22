module Mongoid
  module Symbolize
    def self.included base
      base.extend(ClassMethods)
    end

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
    #   attributes:
    #     user:
    #       enums:
    #         gender:
    #           female: Girl
    #           male: Boy
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

      def symbolize *attr_names
        configuration = {}
        configuration.update(attr_names.extract_options!)

        enum = configuration[:in] || configuration[:within]
        i18n = configuration.delete(:i18n).nil? && !enum.instance_of?(Hash) && enum ? true : configuration[:i18n]
        scopes  = configuration.delete :scopes
        methods = configuration.delete :methods
        capitalize = configuration.delete :capitalize
        validation     = configuration.delete(:validation) != false
        default_opt = configuration.delete :default

        unless enum.nil?
          # Little monkeypatching, <1.8 Hashes aren't ordered.
          # hsh = RUBY_VERSION > '1.9' || !defined?("ActiveSupport") ? Hash : ActiveSupport::OrderedHash

          attr_names.each do |attr_name|
            attr_name = attr_name.to_s

            # Builds Mongoid 'field :name, type: type, :default
            type    = ", type: Symbol"
            default = ", default: :#{default_opt}" if default_opt
            class_eval("field :#{attr_name} #{type} #{default}")

            const =  "#{attr_name}_values"
            if enum.is_a?(Hash)
              values = enum
            else
              values = {}
              enum.map do |val|
                key = val.respond_to?(:to_sym) ? val.to_sym : val
                values[key] = capitalize ? val.to_s.capitalize : val.to_s
              end
            end

            # Get the values of :in
            const_set const.upcase, values unless const_defined? const.upcase
            ev = if i18n
                   # This one is a dropdown helper
                   code =  "#{const.upcase}.map { |k,v| [I18n.t(\"models.attributes.\#{ActiveSupport::Inflector.underscore(self)}.enums.#{attr_name}.\#{k}\"), k] }" #.to_sym rescue nila
                   "def self.get_#{const}; #{code}; end;"
                 else
                   "def self.get_#{const}; #{const.upcase}.map(&:reverse); end"
                 end
            class_eval(ev)

            if methods
              values.each do |value|
                define_method("#{value[0]}?") do
                  self.send(attr_name) == value[0]
                end
              end
            end

            if scopes
              scope_comm = lambda { |*args|  scope(*args)}
              values.each do |value|
                if value[0].respond_to?(:to_sym)
                  scope_comm.call value[0].to_sym, :conditions => { attr_name => value[0].to_sym }
                end
              end
            end

            if validation
              class_eval "validates_inclusion_of :#{attr_names.join(', :')}, #{configuration.inspect}"
            end
          end
        end

        attr_names.each do |attr_name|

          # if default_option
          #   class_eval("def #{attr_name}; read_and_symbolize_attribute('#{attr_name}') || :#{default_option}; end")
          #   class_eval("def #{attr_name}= (value); write_symbolized_attribute('#{attr_name}', value); end")
          #   class_eval("def set_default_for_attr_#{attr_name}; self[:#{attr_name}] ||= :#{default_option}; end")
          #   class_eval("before_save :set_default_for_attr_#{attr_name}")
          # else
          #   class_eval("def #{attr_name}; read_and_symbolize_attribute('#{attr_name}'); end")
          #   class_eval("def #{attr_name}= (value); write_symbolized_attribute('#{attr_name}', value); end")
          # end
          if i18n
            class_eval("def #{attr_name}_text; read_i18n_attribute('#{attr_name}'); end")
          elsif enum
            class_eval("def #{attr_name}_text; #{attr_name.to_s.upcase}_VALUES[#{attr_name}]; end")
          else
            class_eval("def #{attr_name}_text; #{attr_name}.to_s; end")
          end
        end
      end
    end

    # String becomes symbol, booleans string and nil nil.
    # def symbolize_attribute attr
    #   case attr
    #   when String then attr.empty? ? nil : attr.to_sym
    #   when Symbol, TrueClass, FalseClass, Numeric then attr
    #   else nil
    #   end
    # end

    # # Return an attribute's value as a symbol or nil
    # def read_and_symbolize_attribute attr_name
    #   symbolize_attribute self[attr_name]
    # end

    # Return an attribute's i18n
    def read_i18n_attribute attr_name
      return nil unless attr = read_attribute(attr_name)
      I18n.translate("activerecord.attributes.#{ActiveSupport::Inflector.underscore(self.class)}.enums.#{attr_name}.#{attr}") #.to_sym rescue nila
    end

    # # Write a symbolized value. Watch out for booleans.
    # def write_symbolized_attribute attr_name, value
    #   val = { "true" => true, "false" => false }[value]
    #   val = symbolize_attribute(value) if val.nil?

    #   self[attr_name] = val #.to_s # rails 3.1 fix
    # end
  end
end
