# frozen_string_literal: true

require "ruby-progressbar"
class Progress

  def initialize options = {}
    return unless options[:enabled] || true

    @options      = options
    @format       = options[:format]
    @progress_bar = ProgressBar.create(@options)
  end

  def reset title: nil, total: nil, format: nil
    return unless @progress_bar

    @progress_bar.progress = 0
    @progress_bar.title    = title if title
    @progress_bar.total    = total if total
    @progress_bar.format   = format if format
    refresh
  end

  def spin
    until @progress_bar.finished?
      increment
    end
  end

  def total
    return unless @progress_bar

    @progress_bar.total
  end

  def percentage
    return unless @progress_bar

    @progress_bar.to_h["percentage"]
  end

  def refresh
    return unless @progress_bar

    @progress_bar.refresh
  end

  def progress
    return unless @progress_bar

    @progress_bar.progress
  end

  def increment attrs = {}
    return unless @progress_bar

    @progress_bar.increment
    update_attrs(attrs) unless attrs.empty?
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
