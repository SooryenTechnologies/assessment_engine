require 'api_constraints'

Rails.application.routes.draw do

  get '/api' => redirect('/swagger/dist/index.html?url=/apidocs/api-docs.json')
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  get 'users/index'

  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # Api definition
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :users, only: [:index]
      resources :quizzes, except: [:new, :edit] do
        collection do
          get 'duplicate_quiz'
          get 'question_bank'
          get 'get_the_scores_information'
          get 'get_assessments_by_resource_link_ids'
          get 'add_question_to_quiz', as: "add_question_to_quiz"
        end
      end
      resources :quizzes, :as => :quizzes, except: [:new, :edit] do
        resources :quiz_questions, except: [:new, :edit]
        resources :quiz_submissions, only: [:index, :create, :show, :update, :destroy] do
          collection do
            get 'grade_quiz'
            get 'assessment_answers'
            get 'take_quiz'
            get 'timed_quiz'
            get 'quiz_submission_results'
            get 'get_user_attempts'
            post 'whole_next_previous'
          end
        end
        resources :quiz_submission_attempts, only: [:index, :create, :show, :update, :destroy] do
        end
      end
      # We are going to list our resources here
    end
  end
end
