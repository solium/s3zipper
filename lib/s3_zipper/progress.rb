require 'ruby-progressbar'
class Progress
  def initialize options = {}
    return unless options[:enabled] || true
    @options      = options
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

  def finish title: @progress_bar.title, format: @progress_bar.title
    return unless @progress_bar
    @progress_bar.title  = title
    @progress_bar.format = format
    @progress_bar.refresh
    @progress_bar.finish
  end

  def disable
    @progress_bar = nil
  end

  def get_attr attr
    return unless @progress_bar
    @progress_bar.send(attr)
  end

  def to_h
    @progress_bar&.to_h
  end

  def method_missing(name, *args)
    super unless @progress_bar.send(name, *args)
  end
end