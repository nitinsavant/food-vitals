Rails.application.routes.draw do
  root 'static_pages#home'
  get   '/help',   to: 'static_pages#help'
  get   '/submit', to: 'submissions#new'
  post  '/submit', to: 'submissions#create'
  resources :submissions

end
