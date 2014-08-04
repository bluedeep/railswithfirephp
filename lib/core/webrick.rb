module WEBrick
  class HTTPResponse
    include RailsWithFirePHP::HTTPResponse
  end

  class HTTPServer

    alias _rwfp_the_original_service_method service # 'duck punching' the service method

    def service(req,res)        # to get req.properties to the response object
      res._rwfp_set_user_agent( req.meta_vars['HTTP_USER_AGENT'] )
      res._rwfp_set_options( {} )
      _rwfp_the_original_service_method(req,res)
    end
  end

end
