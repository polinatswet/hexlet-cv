# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users, only: :omniauth_callbacks, controllers: { omniauth_callbacks: 'web/omniauth_callbacks' }
  scope '(:locale)', locale: /en|ru/ do
    devise_for :users, skip: :omniauth_callbacks, controllers: { sessions: 'web/devise/sessions',
                                                                 registrations: 'web/devise/registrations',
                                                                 passwords: 'web/devise/passwords',
                                                                 confirmations: 'web/devise/confirmations',
                                                                 unlocks: 'web/devise/unlocks' }
    namespace :api_internal do
      resources :users, only: [] do
        collection do
          get :search
        end
      end
    end

    scope module: :web do
      get '/403', to: 'errors#forbidden', as: :not_forbidden_errors
      get '/404', to: 'errors#not_found', as: :not_found_errors
      match '/500', to: 'errors#server_error', via: :all

      root 'home#index'
      resource :locale, only: [] do
        member do
          get :switch
        end
      end
      resources :careers, only: %i[show] do
        scope module: :careers do
          resources :members, only: %i[show]
          resources :steps, only: [] do
            scope module: :steps do
              resources :members, only: [] do
                member do
                  patch :finish
                end
              end
            end
          end
        end
      end
      resource :employment, only: %i[show]
      resources :vacancies, only: %i[index show]
      # FIXME: фикс дирекшенов с точками типа node.js, убрать, когда определимся, нужно ли будем валидировать направления и запретим указывать точки
      resources :vacancy_filters, only: %i[show], format: false, defaults: { format: 'html' } do
        collection do
          get :search, format: true
        end
      end
      resources :resumes do
        scope module: :resumes do
          resources :answers do
            member do
              patch :change_applying_state
            end
          end
          resources :pdfs, only: :show
          resources :comments
        end
      end
      resources :answers, only: [] do
        scope module: :answers do
          resources :comments
          resources :likes, only: %i[create destroy]
          resources :comments, only: %i[create update destroy]
        end
      end

      namespace :account do
        resources :resumes
        resources :vacancies
        resources :notifications, only: %i[index update]
        resource :newsletters, only: %i[edit update]
        resource :profile, only: %i[edit update show]
      end

      resources :users
      resources :pages

      scope module: :hooks do
        resource :sparkpost
      end

      namespace :admin do
        root 'home#index'
        resources :users, only: %i[index edit update]
        resources :resumes, only: %i[index edit update] do
          member do
            patch :archive
            patch :restore
          end
        end
        resources :vacancies, only: %i[index edit update]
        resources :careers, only: %i[index show new create edit update] do
          scope module: :careers do
            resources :steps, only: %i[show new create edit update]
            resources :members, only: %i[new create] do
              member do
                patch :archive
              end
            end
          end
        end
      end
    end
  end
end
