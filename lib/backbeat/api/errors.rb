module Backbeat
  class Api
    class ValidationError < StandardError
    end

    class NotFoundError < StandardError
    end

    class ApiError < StandardError
    end
  end
end
