Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'localhost:5122', 'localhost:5122', '127.0.0.1:5122', '127.0.0.1:5122'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
