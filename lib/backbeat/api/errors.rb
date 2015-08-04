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

    class InvalidStatusChangeError < StandardError
    end
  end
end
