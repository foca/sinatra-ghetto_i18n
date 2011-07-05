# -*- encoding: utf-8 -*-

module Sinatra
  # Extension that provides simplified I18N for your Sinatra applications.
  #
  # When you register this extension you gain access to 3 application settings,
  # a couple of useful methods, and new options when definining routes and
  # rendering views.
  #
  # The idea behind this is that all the routes in your application are
  # namespaced by the language you want to use.
  #
  # So for example, if you want to provide the "/events" URL in english,
  # spanish, and portuguese, using this extension you would have:
  #
  #   GET /en/events
  #   GET /es/events
  #   GET /pt/events
  #
  # Then, when you render a view (by passing a symbol to erb etc), the view is
  # automatically looked up in a way that will include the language.
  #
  # This assumes you want a separate view file for each language. This means
  # more work maintaining the site, yes, but for very simple websites this is
  # often easier than keeping a translations file.
  #
  # This also helps when you have two widely different languages in which the
  # design is affected by the translation (for example, an LTR and a RTL
  # language.)
  #
  # = Options =
  #
  # When using this extension, you have access to the following settings:
  #
  # == +:languages+ ==
  #
  # You *must* set this to an enumerable that has the language codes your
  # application supports. Any object that responds to #include? and #each works.
  #
  # For example:
  #
  #     set :languages, ["en", "es", "pt"]
  #     set :languages, "en" => "English", "es" => "Español"
  #
  # (The rationale for this is that you might want to use a hash for setting
  # names in order to build links to switch languages, but you can just pass an
  # array if you don't need that)
  #
  # == +:default_language+ ==
  #
  # A string with the 2-letter language code of the default language for your
  # application. Defaults to English.
  #
  # == +:i18n_view_format: ==
  #
  # The path to the internationalized view files. This should be a block that
  # takes two arguments (the original view file, and the language) and must
  # return a symbol.
  #
  # For example:
  #
  #     set :i18n_view_format do |view, lang|
  #       :"#{lang}_#{view}"
  #     end
  #
  # That means when you render the ":some_view" view, you are actually rendering
  # the ":en_some_view" if the user is browsing the English site, or the
  # ":fr_some_view" file if the user is browsing the French site.
  #
  # The default is +lang/view+, so your typical sinatra application will look
  # like this (in case the languages you support are English and Spanish ("en"
  # and "es"):
  #
  #     .
  #     |- website.rb
  #     \- views
  #        |- en
  #        |  |- view_a.erb
  #        |  \- view_b.erb
  #        \- es
  #           |- view_a.erb
  #           \- view_b.erb
  #
  module GhettoI18n
    def self.registered(app) # :nodoc:
      app.helpers Sinatra::GhettoI18n::Helpers
      app.get("/", :skip_i18n => true) { redirect "/#{language}" }

      unless app.respond_to? :i18n_view_format
        app.set(:i18n_view_format) { |view, lang| :"#{lang}/#{view}" }
      end

      unless app.respond_to? :languages
        app.set(:languages, {})
      end

      unless app.respond_to? :default_language
        app.set(:default_language, "en")
      end
    end

    # Define an internationalized GET route for the root. For example:
    #
    #     home do
    #       erb :home
    #     end
    #
    # is equivalent to defining:
    #
    #     get "/:lang", :skip_i18n => true do
    #       erb :home
    #     end
    def home(&block)
      check_language!
      route("GET", "/:lang", { :skip_i18n => true }, &block)
    end

    # Define a condition that makes sure the language provided in the parameters
    # matches the languages defined as an option.
    def check_language!
      condition { self.class.languages.include?(params[:lang]) }
    end

    def route(method, path, options={}, &block) # :nodoc:
      return super if options.delete(:skip_i18n)

      path.gsub! /^\//, ''

      if %W(GET HEAD).include? method
        super method, path, options do
          redirect "/#{language}/#{path}"
        end
      end

      super method, "/:lang/#{path}", options, &block
    end

    module Helpers
      # The language for the current request. If the user is browsing to a
      # language specific URL (ie, :lang is included in the params), then use
      # that.
      #
      # If not, try to figure it out from the Accept-Language HTTP header.
      #
      # If that fails as well, resort to the +default_language+ setting.
      def language
        @_lang ||= params[:lang] || language_from_http ||
          self.class.default_language
      end

      private

      def language_from_http # :nodoc:
        env["HTTP_ACCEPT_LANGUAGE"].to_s.split(",").each do |lang|
          self.class.languages.each do |code, *|
            return code if lang =~ /^#{code}/
          end
        end
        nil
      end

      def render(engine, data, options={}, locals={}, &block) # :nodoc:
        skip_i18n = options.delete(:skip_i18n)

        if Symbol === data && !skip_i18n
          view = self.class.i18n_view_format(data, language)
          super(engine, view, options, locals, &block)
        else
          super
        end
      end
    end
  end
end
