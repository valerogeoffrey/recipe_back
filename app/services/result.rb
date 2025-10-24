# frozen_string_literal: true

# VO representing a result
class Result
  attr_reader :status, :data, :message

  def initialize(status:, data: nil, message: nil)
    @status = status
    @data = data
    @message = message
    freeze
  end

  def success?
    status == :success
  end

  def failed?
    !success?
  end

  def invalid_input?
    status == :invalid_input
  end

  def parsing_failed?
    status == :parsing_failed
  end

  def self.success(data)
    new(status: :success, data: data)
  end

  def self.failed(message, data: nil, status: nil)
    new(status: status || :parsing_failed, message: message, data: data)
  end

  def self.invalid(message)
    new(status: :invalid_input, message: message)
  end

  def to_h
    { status: status, data: data, message: message }
  end
end
