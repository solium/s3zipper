require 'ruby-progressbar'
class Progress
  def initialize options = {}
    return unless options[:enabled]
    @options      = options
    @title        = options[:title]
    @total        = options[:total]
    @format       = options[:format]
    @progress_bar = ProgressBar.create(@options)
  end

  def progress
    return unless @progress_bar
    @progress_bar.progress
  end

  def increment
    return unless @progress_bar
    @progress_bar.increment
  end

  def update attr, value
    return unless @progress_bar
    @progress_bar.send("#{attr}=", value)
    @progress_bar.refresh
  end

  def finish title: @title, format: @format
    return unless @progress_bar
    @progress_bar.title  = title
    @progress_bar.format = format
    @progress_bar.refresh
    @progress_bar.finish
  end

  def disable
    @progress_bar = nil
  end
end