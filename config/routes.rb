Rails.application.routes.draw do
   post '/search_queries/record', to: 'search_queries#record'
  root "search_queries#index"
  get '/search_queries/analytics', to: 'search_queries#analytics'
end
