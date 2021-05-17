# @example
#    class Event < ApplicationRecord
#      validates :starts_at, datetime: { earlier_than: proc { |event| event.ends_at } }
#      validates :ends_at, datetime: { later_than: :today }
#      validates :archived_at, datetime: { later_than: 1.year.from_now }
#      # ...
#
class DatetimeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, :invalid) if invalid_type?(value)

    if earlier_than_value(record) && value.utc >= earlier_than_value(record).utc
      record.errors.add(
        attribute,
        (options[:message] || :too_late),
        value: earlier_than_value(record)
      )
    end

    if later_than_value(record) && value.utc <= later_than_value(record).utc
      record.errors.add(
        attribute,
        (options[:message] || :too_soon),
        value: later_than_value(record)
      )
    end
  end

  private

  def earlier_than_value(record)
    comparative_value(record, :earlier_than)
  end

  def later_than_value(record)
    comparative_value(record, :later_than)
  end

  def comparative_value(record, comparative)
    return unless options[comparative]

    if options[comparative].respond_to?(:call)
      options[comparative].call(record)
    elsif Time.now.respond_to?(options[comparative])
      Time.now.public_send(options[comparative])
    else
      options[comparative]
    end
  end

  def invalid_type?(value)
    return false if value.is_a?(Time)
    return false if value.is_a?(DateTime)
    return false if value.is_a?(Date)

    true
  end
end
