module NewRelicLogger
  class LogQueue

    def initialize(max_queue_size)
      if max_queue_size <= 0
        raise IllegalArgumentException.new('max_queue_size must be greater than 0')
      end

      @queue_open     = true
      @max_queue_size = max_queue_size
      @queue          = []
      @mutex          = Mutex.new
      @cv             = ConditionVariable.new
    end

    def <<(message)
      unless @queue_open
        raise ClosedQueueError.new('queue closed')
      end

      @mutex.synchronize do
        @queue << message
        @cv.signal if @queue.length >= @max_queue_size
      end
    end

    def concat(messages)
      unless @queue_open
        raise ClosedQueueError.new('queue closed')
      end

      @mutex.synchronize do
        @queue.concat(messages)
        @cv.signal if @queue.length >= @max_queue_size
      end
    end

    def pop_with_timeout(timeout)
      if timeout <= 0
        raise IllegalArgumentException.new('timeout must be greater than 0')
      end

      @mutex.synchronize do
        while @queue.empty? || !@queue_open
          @cv.wait(@mutex, timeout)
        end

        @queue.shift(@queue_open ? @max_queue_size : @queue.length)
      end
    end

    def empty?
      @mutex.synchronize do
        @queue.empty?
      end
    end

    def close
      @queue_open = false
      @cv.signal
    end
  end
end
