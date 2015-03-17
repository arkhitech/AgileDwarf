resources :all_sprints, only: :index
resources :adsprints, :adtasks, except: %i(index show new create edit update destroy) do
  collection do
    get :list
  end
end
resources :adsprintinl, only: :create do
  member do
    match :inplace, via: %i(put patch)
  end
end
resources :adburndown, only: :show
resources :adtaskinl, only: %i(update create) do
  member do
    get :tooltipp
    match :inplace, via: %i(put patch)
  end
  collection do
    post :spent
  end
end
