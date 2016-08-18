Rails.application.routes.draw do
  resources :submissions
  root 'static_pages#home'
  get 'static_pages/help'

end
