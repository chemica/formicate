require "formicate/version"

module Formicate

  class Base
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attr_accessor :params

    class << self
      attr_writer :cleaner_methods, :form_field_names, :processors, :default_values

      def cleaner_methods; @cleaner_methods ||= [] end
      def form_field_names; @form_field_names ||= [] end
      def processors; @processors ||= { valid: [], invalid: [], always: [] } end
      def default_values; @default_values ||= {} end

      def add_cleaner(method_name)
        self.cleaner_methods << method_name.to_sym
      end

      def form_fields(*fields)
        self.form_field_names += fields.map &:to_sym
      end

      def add_processor(method_name, type = :valid)
        type = type.to_sym; method_name = method_name.to_sym
        raise ArgumentError.new("Invalid processor type #{type}") unless type.in? [:valid, :invalid, :always]
        self.processors[type] << method_name
      end

      def defaults(hash)
        self.default_values = default_values.merge hash
      end

    end

    def initialize(*args, &block)
      # Create an accessor for all form fields.
      self.class.form_field_names.each do |field|
        self.class.send :attr_accessor, field
      end

      after_initialize(*args, &block)
    end

    # Receive the request parameters and load up the attr_accessors
    def process(request_params)
      model_name = self.class.model_name.singular
      params = request_params[model_name.to_sym] ||
          request_params[model_name] || {}
      self.params = params

      self.class.form_field_names.each do |field|
        # Cope with request params using both symbols and strings.
        self.send("#{field}=", params[field]) if params[field].present?
        self.send("#{field}=", params[field.to_s]) if params[field.to_s].present?
      end

      # Call main data cleaning method
      clean_data

      # Call cleaner methods registered by concerns
      send_all self.class.cleaner_methods

      # Apply defaults to cleaned attributes. (defaults should not need cleaning)
      self.class.default_values.each do |field, value|
        self.send("#{field}=", value) if self.send(field).blank?
      end

      if valid = valid?
        process_valid
        send_all self.class.processors[:valid]
      else
        process_invalid
        send_all self.class.processors[:invalid]
      end
      process_always
      send_all self.class.processors[:always]
      valid
    end

    # Return a hash of utilised form fields against their values
    def attributes
      self.class.form_fields.select{ |f| self[f] }.
          each_with_object({}){ |f, h| h[f] = self[f] }
    end

    # Allow access of form fields through [] operator.
    def [](index)
      index = index.to_sym
      self.send(index) if index.in? self.class.form_fields
    end

    def []=(index, value)
      self.send("#{index}=", value) if index.in? self.class.form_fields
    end

    # Required for non-persisted model type objects
    def persisted?
      false
    end

    #
    # def self.i18n_scope
    #   "form_objects"
    # end

    private

    # Call all method names from an array of symbols
    def send_all(method_names)
      method_names.each { |m| send m }
    end

    # Override with any extra set-up required
    def after_initialize(*args, &block); end

    # Override with any custom data processing or cleansing.
    def clean_data; end

    # Override with any side effects of form processing. (Updating models, etc.)
    def process_valid; end

    # Override with anything that needs to run if the form is invalid
    def process_invalid; end

    # Override with anything that needs to run whether the form is valid or invalid
    def process_always; end
  end
end
