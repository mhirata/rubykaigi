require 'omniauth/openid'
require 'openid/store/filesystem'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter,  configatron.twitter.consumer_key, configatron.twitter.consumer_secret
  provider :github,   configatron.github.client_id, configatron.github.secret, {:client_options => {:ssl => {:ca_path => OpenSSL::X509::DEFAULT_CERT_DIR}}}
  provider :password, configatron.password_secret, :identifier_key => 'username'

  openid_filesystem = OpenID::Store::Filesystem.new(Rails.root + 'tmp/openid')
  provider :open_id, openid_filesystem, :name => 'google', :identifier      => 'https://www.google.com/accounts/o8/id'
  provider :open_id, openid_filesystem, :name => 'yahoo', :identifier       => 'http://yahoo.com'
  provider :open_id, openid_filesystem, :name => 'yahoo_japan', :identifier => 'http://yahoo.co.jp'
  provider :open_id, openid_filesystem, :name => 'mixi', :identifier        => 'http://mixi.jp'
  provider :open_id, openid_filesystem, :name => 'open_id'
end

require 'digest/sha1'
require 'omniauth/core'

module OmniAuth
  module Strategies
    class Password
      include OmniAuth::Strategy

      def initialize(app, secret = 'changethisappsecret', options = {}, &block)
        @secret = secret
        super(app, :password, options, &block)
      end

      attr_reader :secret

      def request_phase
        return fail!(:missing_information) unless request[:identifier] && request[:password]
        return fail!(:password_mismatch) if request[:password_confirmation] && request[:password_confirmation] != '' && request[:password] != request[:password_confirmation]
        env['REQUEST_METHOD'] = 'GET'
        env['PATH_INFO'] = request.path + '/callback'
        env['omniauth.auth'] = auth_hash(encrypt(request[:identifier], request[:password]))
        call_app!
      end

      def auth_hash(crypted_password)
        OmniAuth::Utils.deep_merge(super(), {
          'uid' => crypted_password,
          'user_info' => {
            @options[:identifier_key] => request[:identifier]
          }
        })
      end

      def callback_phase
        call_app!
      end

      def encrypt(identifier, password)
        Digest::SHA1.hexdigest([identifier, password, secret].join('::'))
      end
    end
  end
end
