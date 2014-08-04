module RailsWithFirePHP 
  RWFP_FUNCTION_NAMES = %w(LOG INFO WARN ERROR)
  module Common
    #FirePHP header template
    RWFP_INIT_HEADERS = { 'X-Wf-Protocol-1' => 'http://meta.wildfirehq.org/Protocol/JsonStream/0.2',
                        'X-Wf-1-Plugin-1' =>'http://meta.firephp.org/Wildfire/Plugin/FirePHP/Library-FirePHPCore/0.2.0'}
    RWFP_INIT_HEADERS_LOG = { 'X-Wf-1-Structure-1' => 'http://meta.firephp.org/Wildfire/Structure/FirePHP/FirebugConsole/0.1' }
    RWFP_INIT_HEADERS_DUMP = { 'X-Wf-1-Structure-2' => 'http://meta.firephp.org/Wildfire/Structure/FirePHP/Dump/0.1' }
    RWFP_KINDS = %w(LOG INFO WARN ERROR DUMP TRACE EXCEPTION TABLE)
    RWFP_LEGACY_WARNING = { 'X-FirePHP-Data-100000000001' => '{' ,
            'X-FirePHP-Data-300000000001' => '"FirePHP.Firebug.Console":[',
            'X-FirePHP-Data-300000000002' => '[ "INFO", "This version of FirePHP is no longer supported by rwfp. Please update to 0.2.1 or higher." ],',
            'X-FirePHP-Data-399999999999' => '["__SKIP__"]],',
            'X-FirePHP-Data-999999999999' => '"__SKIP__":"__SKIP__"}' }
    MAX_LENGTH = 4000

    #from utf-8 to unicode
    def toUnicode obj
      obj.unpack('U*').map {|i| i>=592 ? ("\\u" + i.to_s(16).rjust(4, '0')) : [i].pack('U') }.join
    end

    #build header 
    def _rwfp_build_headers msg,kind='LOG',label=nil
      logheaders = []
      t_pref,g_kind = kind == 'DUMP' ? [ 2, 'DUMP' ] : [ 1, 'LOG' ]
      file, line, function = caller[2].split ':'
      msg_meta = { 'Type' => kind, 'File' => file, 'Line' => line }
      msg_meta['Label'] = label ? label + '(' + msg.class.to_s + ')' : '(' + msg.class.to_s + ')'
      #@fire_msg_index = 0 unless instance_variables.member? '@fire_msg_index'
      @fire_msg_index = 0 if not @fire_msg_index
      msg = _rwfp_mask_ruby_types( Marshal.load(Marshal.dump(msg)) ) if ( @rwfp_options.has_key? :mask_ruby_types && :mask_ruby_types )
      msg_u = toUnicode msg.to_json
      label_u = toUnicode label.to_json
      msg_meta_u= toUnicode msg_meta.to_json
      msg = kind == 'DUMP' ? "{#{label_u}:#{msg_u}}" : "[#{msg_meta_u},#{msg_u}]"
      (msg.gsub /.{#{MAX_LENGTH}}/ do |m| "#{m}\n" end).split( "\n" ).each_with_index do |msg_part,ind|
        @fire_msg_index += 1
        logheaders << [ "X-Wf-1-#{t_pref}-1-#{@fire_msg_index}", "#{msg.size if ind == 0}|#{msg_part}|#{'\\' if ind < msg.size/MAX_LENGTH}" ] 
      end
      unless instance_variables.member? "@rwfp_inited_#{g_kind.downcase}"
        RailsWithFirePHP::Common::const_get( "RWFP_INIT_HEADERS_#{g_kind}" ).each_pair { |k,v| logheaders << [ k, v ] }
        instance_variable_set( "@rwfp_inited_#{g_kind.downcase}", true )
      end
      return logheaders
    end

    def _rwfp_set_options opts
      @rwfp_options = {} unless instance_variables.member? '@rwfp_options'
      @rwfp_options.merge! opts
    end

    def _rwfp_initialize_request ua
      @firephp_version = ua.match( /FirePHP\/(\d+)\.(\d+)\.([\db.]+)/)
      @firephp_version = @firephp_version[1,3].map {|i| i.to_i} if @firephp_version
      firephp_01_version = ( @firephp_version || [0,2] )[0,2].join('.').to_f<0.2 
      @firephpruby_skip = @firephp_version == nil || firephp_01_version
      logheaders = firephp_01_version ? RWFP_LEGACY_WARNING : RWFP_INIT_HEADERS
      logheaders['X-FirePHP-RendererURL'] = @rwfp_options[:renderer_url] if @rwfp_options.has_key? :renderer_url
      logheaders['X-FirePHP-ProcessorURL'] = @rwfp_options[:processor_url] if @rwfp_options.has_key? :processor_url
      return logheaders
    end

    def rwfp_internal_log msg
      @fire_msg_index = 0 unless instance_variables.member? '@fire_msg_index'
      @fire_msg_index += 1
      msg = "[#{{:Type=>'LOG',:Label=>'____________________________ internal message'}.to_json},#{msg.to_json}]"
      puts "X-Wf-1-1-1-#{@fire_msg_index}: #{msg.size}|#{msg}|"
    end

    def _rwfp_mask_ruby_types data, skip=true # skip masking if not hash key
      #rwfp_internal_log data.class.to_s
      if data.is_a? String
        return data
      elsif data.is_a? Integer
        return "__INT__#{data.to_s}__INT__"
      elsif data.is_a? Numeric
        return skip ? data : "__NUM__#{data.to_s}__NUM__"
      elsif data.is_a? TrueClass or data.is_a? FalseClass
        return skip ? data : "__BOOL__#{data.to_s}__BOOL__"
      elsif data.nil?
        return skip ? data : '__NIL__nil__NIL__'
      elsif data.is_a? Symbol
        return "__SYM__:#{data.to_s}__SYM__"
      elsif data.is_a? Array
        #rwfp_internal_log 'wird'
        return data.map { |v| _rwfp_mask_ruby_types v }
      elsif data.is_a? Hash
        k_types = [ Symbol, Fixnum, Bignum, Float, Range, TrueClass, FalseClass, NilClass ]
        j_types = [ Array, Hash ]
        data.each { |k,v| data[k] = _rwfp_mask_ruby_types v }
        keys_to_mask = data.keys.select { |k| k_types.include? k.class }
        keys_to_mask.each { |k| nk = _rwfp_mask_ruby_types k,false; data[nk] = data[k]; data.delete k }
        keys_to_jsonize = data.keys.select { |k| j_types.include? k.class }
        keys_to_jsonize.each do |k| 
          nk = _rwfp_mask_ruby_types( k,false ).to_json 
          data["__JSON__#{nk}__JSON__"] = data[k]
          data.delete k
        end
        return data
      elsif data.is_a? Range
        return "__RNG__#{data.to_s}__RNG__"
      end
      rwfp_internal_log 'shit happens - class: ' + data.class.to_s
      return data
    end
  end
  
  class CGI
    include Common
    def initialize options={}
      _rwfp_set_options options
      ENV['HTTP_USER_AGENT'] = 'FirePHP/0.2.b.7' unless ENV['HTTP_USER_AGENT'] # for being callable from shell
      logheaders = _rwfp_initialize_request ENV['HTTP_USER_AGENT'] 
      return if @firephpruby_skip
      logheaders.each_pair { |k,v| puts "#{k}: #{v}" }
    end
    def firelog msg,kind='LOG', label=nil
      return if @firephpruby_skip
      logheaders = _rwfp_build_headers msg,kind,label
      logheaders.each { |h| puts "#{h[0]}: #{h[1]}" }
    end
    RWFP_FUNCTION_NAMES.each { |x| self.class_eval "def #{x.downcase} msg, label=nil; firelog msg,'#{x}',label; end" }
    def dump obj, label=''
      firelog obj,'DUMP', label
    end
    def send_index_header # not needed since 0.2.b.4 or something like
      puts "X-Wf-1-Index: #{@fire_msg_index.to_s}"
    end
  end

  module HTTPResponse
    include Common
    def fire_clog msg,kind='LOG', label=nil
      return if defined?( @firephpruby_skip ) && @firephpruby_skip
      logheaders = _rwfp_build_headers msg,kind,label
      logheaders.each { |h| @header[h[0]] = h[1] }
      return if defined? @rwfp_inited
      _rwfp_initialize_request( @rwfp_user_agent ).each_pair { |k,v| @header[k] = v }
      @rwfp_inited = true
    end
    def fire_options options={}
      _rwfp_set_options options
    end
    RWFP_FUNCTION_NAMES.each { |x| self.module_eval "def fire_#{x.downcase} msg, label=nil; fire_clog msg,'#{x}',label; end" }
    def fire_dump obj, label=''
      fire_clog obj,'DUMP', label
    end
    def _rwfp_set_user_agent ua
      @rwfp_user_agent = ua
    end
  end

  module Rails
    include HTTPResponse
    def _rwfp_set_header_var    # the @header-hash from WEBrick/Mongrel-response-classes 
      #@header = headers  # is called @headers in the Rails-response-class
    end
    module Interface
      RWFP_FUNCTION_NAMES.each { |x| self.module_eval "def fire_#{x.downcase} msg, label=nil; response.fire_clog msg,'#{x}',label; end" }

      def fire_dump obj, label=''
        response.fire_clog obj,'DUMP', label
      end
      def fire_options opts={}
        response.fire_options opts
      end
      def fb msg, label=nil
        fire_log msg, label
      end
    end
  end
end

