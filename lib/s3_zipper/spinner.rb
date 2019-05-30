# frozen_string_literal: true

require "ruby-progressbar"
require "concurrent-ruby"
class S3Zipper
  class Spinner
    include Concurrent::Async

    def initialize title: "", enabled: true, steps: %w[▸▹▹▹▹▹ ▹▸▹▹▹▹ ▹▹▸▹▹▹ ▹▹▹▸▹▹ ▹▹▹▹▸▹ ▹▹▹▹▹▸ ▹▹▹▹▹]
      return unless enabled || true

      @progress_bar = ProgressBar.create(
        format:                           "[%B] %t",
        total:                            nil,
        length:                           100,
        title:                            title,
        autofinish:                       false,
        unknown_progress_animation_steps: steps,
      )
    end

    def reset title: nil, total: nil, format: nil
      return unless @progress_bar

      @progress_bar.progress = 0
      @progress_bar.title    = title if title
      @progress_bar.total    = total if total
      @progress_bar.format   = format if format
      refresh
    end

    def start
      async.spin
    end

    def spin
      return unless @progress_bar
      until @progress_bar.finished?
        increment
        sleep(2)
      end
    end

    def increment
      return unless @progress_bar

      @progress_bar.increment
    end

    def finish title: nil
      return unless @progress_bar

      @progress_bar.title  = title if title
      @progress_bar.format = "[✔] %t"
      @progress_bar.finish
    end
  end
end
