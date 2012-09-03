# encoding: UTF-8

class Object
  def blank?
  respond_to?(:empty?) ? empty? : !self
  end

  def present?
    !blank?
  end

  def presence
    self if present?
  end
end

class NilClass
  def blank?
    true
  end
end

class FalseClass
  def blank?
    true
  end
end

class TrueClass
  def blank?
    false
  end
end

class Array
  alias_method :blank?, :empty?
end

class Hash
  alias_method :blank?, :empty?
end

class String
  NON_WHITESPACE_REGEXP = %r![^\s#{[0x3000].pack("U")}]!

  if defined?(Encoding) && "".respond_to?(:encode)
    def encoding_aware?
      true
    end
  else
    def encoding_aware?
      false
    end
  end

  def blank?
    if encoding_aware?
      self !~ /[^[:space:]]/
    else
      self !~ NON_WHITESPACE_REGEXP
    end
  end
end

class Numeric
  def blank?
    false
  end
end
