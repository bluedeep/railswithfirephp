  module ActionController
    class Base
      include RailsWithFirePHP::Rails
      include RailsWithFirePHP::Rails::Interface
      unless defined? _rwfp_the_original_process_method 
        alias _rwfp_the_original_process_method process
        #def process(action, *arguments )
        def process(action, *arguments)
          response._rwfp_set_user_agent request.env['HTTP_USER_AGENT']
          response._rwfp_set_header_var
          response._rwfp_set_options( {} )
          _rwfp_the_original_process_method(action, *arguments)
        end
      end

      # enabled fb in model.rb
      before_filter :_rwfp_modellog_clear
      after_filter :_rwfp_modellog_show
      def _rwfp_modellog_clear
        ActiveRecord::Base::ModelLog.clear
      end
      def _rwfp_modellog_show
        ActiveRecord::Base::ModelLog.each do |log|
          fb log[:msg], log[:label]
        end
      end 
    end
    class AbstractResponse
      include RailsWithFirePHP::Rails
    end
  end

