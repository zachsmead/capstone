Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  root to: "books#new"

  resources :books

  # get "/books" => "books#index"
  # get "/books/new" => "books#new"
  # post "/books" => "books#create"
  # get "/books/:id" => "books#show"

  get "/users/list" => "follows#index"
  post "/follows" => "follows#create"

  post "/book_likes" => "books#like"

  get "/aws-test" => "books#aws_test"








end
