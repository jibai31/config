Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :cards, only: %i[index show]
      resources :tastings, only: %i[index update]
    end
  end
end
