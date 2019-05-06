require 'ruby-progressbar'
class Progress
  def initialize options = {}
    return unless options[:enabled] || true
    @options      = options
    @format       = options[:format]
    @progress_bar = ProgressBar.create(@options)
  end

  def reset(title: nil, total: nil, format: nil)
    @progress_bar.progress = 0
    @progress_bar.title    = title
    @progress_bar.total    = total
    @progress_bar.format   = format
    refresh
  end

  def total
    @progress_bar&.total
  end

  def percentage
    @progress_bar&.to_h['percentage']
  end

  def refresh
    @progress_bar&.refresh
  end

  def progress
    @progress_bar&.progress
  end

  def increment
    @progress_bar&.increment
  end

  def update_attrs attrs
    attrs.each(&method(:update))
  end

  def update attr, value
    return unless @progress_bar
    @progress_bar.send("#{attr}=", value)
  end

  def finish title: nil, format: nil
    return unless @progress_bar
    @progress_bar.title  = title if title
    @progress_bar.format = format if format
    @progress_bar.finish
  end

  def disable
    @progress_bar = nil
  end

  def get_attr attr
    return unless @progress_bar
    @progress_bar.send(attr)
  end
end