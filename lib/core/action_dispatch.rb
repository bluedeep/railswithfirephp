module ActionDispatch
  class Response
    include RailsWithFirePHP::Common
    include RailsWithFirePHP::HTTPResponse
    include RailsWithFirePHP::Rails
  end
end


