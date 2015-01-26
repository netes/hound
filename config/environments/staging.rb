require_relative "production"

Houndapp::Application.configure do
  config.action_mailer.default_url_options = { :host => 'hound-staging.devguru.co' }
  config.force_ssl = true
end
