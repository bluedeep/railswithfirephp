#encoding: utf-8
# Copyright (c) 2014-2018 Bluedeep
#
# RailsWithFirePHP is a module for Rails. It allows you to print messages and objects from Rails Models Controllers and Views to the FirePHP console.
# This module is improved from FirePHRuby 
# RailsWithFirePHP is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
# autor: bluedeep
require "railswithfirephp/version"
require File.dirname(__FILE__) + "/core/rails_with_firephp.rb"

if defined? ActiveRecord # enabled fb in model.rb
  require File.dirname(__FILE__) + "/core/active_record.rb"
end

if defined? ActionController # guessing Rails should be a little bit more detailed.
  require File.dirname(__FILE__) + "/core/action_dispatch.rb"
  require File.dirname(__FILE__) + "/core/action_controller.rb"
  require File.dirname(__FILE__) + "/core/action_view.rb"
elsif defined? WEBrick
  require File.dirname(__FILE__) + "/core/webrick.rb"
elsif defined? Mongrel
  require File.dirname(__FILE__) + "/core/mongrel.rb"
end
