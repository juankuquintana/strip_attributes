require "active_model"

module ActiveModel::Validations::HelperMethods
  # Strips whitespace from model fields and converts blank values to nil.
  def strip_attributes(options = nil)
    StripAttributes.validate_options(options)

    before_validation do |record|
      if options
        if_option = options[:if].nil? ? true : options[:if]
        if_option = (if_option==true || if_option==false) ? if_option : record.public_send(if_option)
        if options && !if_option
          next
        end
      end
      StripAttributes.strip(record, options)
    end
  end

  # <b>DEPRECATED:</b> Please use <tt>strip_attributes</tt> (non-bang method)
  # instead.
  def strip_attributes!(options = nil)
    warn "[DEPRECATION] `strip_attributes!` is deprecated.  Please use `strip_attributes` (non-bang method) instead."
    strip_attributes(options)
  end
end

module StripAttributes
  VALID_OPTIONS = [:only, :except, :allow_empty, :collapse_spaces, :regex, :strip, :non_breaking, :if]
  MULTIBYTE_SUPPORTED = "\u0020" == " "

  # Necessary because Rails has removed the narrowing of attributes using :only
  # and :except on Base#attributes
  def self.narrow(attributes, options = {})
    if except = options && options[:except]
      except = Array(except).collect { |attribute| attribute.to_s }
      attributes.except(*except)
    elsif only = options && options[:only]
      only = Array(only).collect { |attribute| attribute.to_s }
      attributes.slice(*only)
    else
      attributes
    end
  end

  def self.strip(record, options)
      attributes = self.narrow(record.attributes, options)

      if options
        allow_empty     = options[:allow_empty].nil? ? false : options[:allow_empty]
        collapse_spaces = options[:collapse_spaces].nil? ? false : options[:collapse_spaces]
        regex           = options[:regex]
        strip           = options[:strip].nil? ? false : options[:strip]
        non_breaking    = options[:non_breaking].nil? ? true : options[:non_breaking]
      end

      attributes.each do |attr, value|
        original_value = value

        if value.respond_to?(:strip)
          value.strip! if !value.nil? && strip
          value = (value.empty? && !allow_empty) ? nil : value
        end

        if regex && value.respond_to?(:gsub!)
          value.gsub!(regex, '')
        end

        if MULTIBYTE_SUPPORTED && non_breaking
          # Remove leading and trailing Unicode invisible and whitespace characters.
          # The POSIX character class [:space:] corresponds to the Unicode class Z
          # ("separator"). We also include the following characters from Unicode class
          # C ("control"), which are spaces or invisible characters that make no
          # sense at the start or end of a string:
          #   U+180E MONGOLIAN VOWEL SEPARATOR
          #   U+200B ZERO WIDTH SPACE
          #   U+200C ZERO WIDTH NON-JOINER
          #   U+200D ZERO WIDTH JOINER
          #   U+2060 WORD JOINER
          #   U+FEFF ZERO WIDTH NO-BREAK SPACE
          if value.respond_to?(:gsub!)
            value.gsub!(/\A[\u180E\u200A\u200B\u200C\u200D\u2060\uFEFF]+|[\u180E\u200A\u200B\u200C\u200D\u2060\uFEFF]+\z/, '')
          end
          value.strip! if !value.nil? && strip && value.respond_to?(:strip)
        end

        if collapse_spaces && value.respond_to?(:squeeze!)
          value.squeeze!(' ')
        end

        record[attr] = value if original_value != value
      end
  end

  def self.validate_options(options)
    if keys = options && options.keys
      unless (keys - VALID_OPTIONS).empty?
        raise ArgumentError, "Options does not specify #{VALID_OPTIONS} (#{options.keys.inspect})"
      end
    end
  end
end
