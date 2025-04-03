Rails.application.routes.draw do
  devise_for :users
  resources :leads
  root "leads#index"
  patch '/leads/:id/update_description', to: 'leads#update_description', as: :update_description
  patch '/leads/:id/update_status', to: 'leads#update_status', as: :update_status
end
