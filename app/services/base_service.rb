# frozen_string_literal: true

class BaseService
  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end
end
