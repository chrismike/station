require 'digest/sha1'

module ActiveRecord #:nodoc:
  # Agents are models that can perform actions in the application. The paradigm of Agents are Users.
  #
  # == Authentication
  # Agents are authenticated in the application. See Authentication module for methods supported.
  #
  # == Authorization
  # Agents perform a Role in each Stage they participate. This Role defines the permissions the Agent can 
  # perform in the Stage. See ActionController::Authorization to define filters in your application.
  #
  # Include Agent functionality in your models using ActsAsMethods#acts_as_agent
  module Agent
    class << self
      # Returns the first model that acts as Agent, has activation enabled and 
      # login and password
      def activation_class
        classes.select{ |a| a.agent_options[:activation] && 
          a.agent_options[:authentication].include?(:login_and_password) }.first
      end

      # An Array with Agent classes supporting authentication @method@
      def authentication_classes(method = nil)
        classes.select{ |klass|
          klass.agent_options[:authentication] 
        }.select { |klass|
          method ?
            klass.agent_options[:authentication].include?(method) :
            ! klass.agent_options[:authentication].blank? 
        }
      end

      # An Array with all authentication methods supported by the application
      def authentication_methods
        classes.map{ |a| a.agent_options[:authentication] }.flatten.uniq
      end

      # All Agent instances, sort by name
      def all
        classes.map(&:all).flatten.uniq.sort{ |x, y| x.name <=> y.name }
      end

      def included(base) #:nodoc:
        base.extend ActsAsMethods
      end
    end

    module ActsAsMethods
      # Provides an ActiveRecord model with Agent capabilities
      #
      # Options
      # <tt>authentication</tt>:: Array with Authentication methods supported for this Agent. Defaults to <tt>[ :login_and_password, :openid, :cookie_token ]</tt>.
      # <tt>openid_server</tt>:: Support for OpenID Server. Defaults to false
      # <tt>activation</tt>:: Agent must verify email. Defaults to false
      # <tt>invite</tt>:: Agent can be invited to application. Can be <tt>false</tt>. Defaults to <tt>:email</tt>
      def acts_as_agent(options = {})
        ActiveRecord::Agent.register_class(self)

        options[:authentication] ||= [ :login_and_password, :openid, :cookie_token ]
        options[:openid_server]  ||= false
        options[:activation]     ||= false
        options[:invite] = :email if options[:invite].nil?
        
        # Set agent options
        #
        cattr_reader :agent_options
        class_variable_set "@@agent_options", options

        # Load Authentication Methods
        #
        options[:authentication].each do |method|
          include "ActiveRecord::Agent::Authentication::#{ method.to_s.camelize }".constantize
        end

        if options[:openid_server]
          include OpenidServer
        end

        if options[:authentication].include?(:login_and_password)
          include PasswordReset
        end

        # Loads agent email verification
        if options[:activation]
          include Activation
        end

        if options[:invite]
          if table_exists? && ! column_names.include?(options[:invite].to_s)
            raise "#{ self.to_s } class hasn't column #{ options[:invite] }" 
          end
          include Invite
        end

        has_many :agent_performances, 
                 :class_name => "Performance", 
                 :dependent => :destroy,
                 :as => :agent

        extend  ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      # Does this Agent class supports password recovery?
      def password_recovery?
        agent_options[:authentication].include?(:login_and_password) && agent_options[:activation]
      end
    end

    module InstanceMethods
      # Does this Agent needs to set a local password?
      # True if it supports <tt>:login_and_password</tt> authentication method
      # and it hasn't any OpenID Owning
      def needs_password?
        # False is Login/Password is not supported by this Agent
        return false unless agent_options[:authentication].include?(:login_and_password)
        # False if OpenID is suported and there is already an OpenID Owning associated
        ! (agent_options[:authentication].include?(:openid) && !openid_identifier.blank?)
      end

      # All Stages in which this Agent has a Performance
      #
      # Can pass options to the list:
      # type:: the class of the Stage requested (Doesn't work with STI!)
      #
      def stages(options = {})
        agent_performances.stage_type(options[:type]).map(&:stage)
      end

      # Agents that have at least one Role in stages
      def fellows
        stages.map(&:actors).flatten.uniq.sort{ |x, y| x.name <=> y.name }
      end

      def service_documents
        if self.agent_options[:authentication].include?(:openid)
          openid_uris.map(&:atompub_service_document)
        else
          Array.new
        end
      end
    end
  end
end
