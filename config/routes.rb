Rails.application.routes.draw do
  root 'static_pages#home'
  get   '/help',   to: 'static_pages#help'
  post   '/',   to: 'submissions#create'
  resources :submissions

end
