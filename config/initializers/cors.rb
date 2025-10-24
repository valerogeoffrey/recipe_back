Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://recipe-front-sigma.vercel.app/','https://recipe-front-sigma.vercel.app','localhost:5122', 'localhost:5122', '127.0.0.1:5122', '127.0.0.1:5122'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
