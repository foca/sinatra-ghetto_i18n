Gem::Specification.new do |s|
  s.name    = "sinatra-ghetto_i18n"
  s.version = "0.1.0"
  s.date    = "2011-07-04"

  s.description = "Oversimplified I18N for your Sinatra application."
  s.summary     = "I18n for simple apps."
  s.homepage    = "http://github.com/foca/sinatra-ghetto_i18n"

  s.authors = ["Nicolas Sanguinetti"]
  s.email   = "contacto@nicolassanguinetti.info"

  s.require_paths     = ["lib"]
  s.has_rdoc          = true
  s.rubygems_version  = "1.3.5"

  s.add_dependency "sinatra"

  s.files = %w[
    .gitignore
    LICENSE
    README.rdoc
    sinatra-ghetto_i18n.gemspec
    lib/sinatra/ghetto_i18n.rb
  ]
end
