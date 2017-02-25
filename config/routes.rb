Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
   # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
   root 'issues#index'
   resources :issues, only: [:index, :create] do
     post 'resolve' => 'issues#resolve'
     post 'create_message' => 'messages#create'
   end

   authenticated :user do
    scope 'admin' do
      get 'parse' => 'admin_issues#parse'
      resources :issues do
        post 'resolve' => 'admin_issues#resolve'
        post 'read_messages' => 'admin_issues#read_messages'
        post 'reply' => 'admin_issues#reply'
        post 'set_assignee' => 'admin_issues#set_assignee'
      end
    end
  end

  unauthenticated :user do
    devise_scope :user do
      get "register" => "devise/sessions#new"
    end
  end
end
