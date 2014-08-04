module Mongrel
  class HttpResponse
    include RailsWithFirePHP::HTTPResponse
    def fire_init req, options={}
      _rwfp_set_user_agent req.params['HTTP_USER_AGENT']
      _rwfp_set_options options
    end
  end
end
