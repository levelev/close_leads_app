Rails.application.routes.draw do
  devise_for :users
  resources :leads
  root "leads#index"
end
