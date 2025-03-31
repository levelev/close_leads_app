Rails.application.routes.draw do
  root "leads#index"
  patch '/leads/:id/update_description', to: 'leads#update_description', as: :update_description
end
