module Backbeat
  class Api
    class ValidationError < StandardError
    end

    class NotFoundError < StandardError
    end

    class ApiError < StandardError
    end

    class AuthenticationError < StandardError
    end
  end
end
