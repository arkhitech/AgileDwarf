match 'adburndown/(:action(/:id))', :controller => 'adburndown', via: %i(get post put patch delete)
match 'adsprintinl/(:action(/:id))', :controller => 'adsprintinl', via: %i(get post put patch delete)
match 'adsprints/(:action(/:id))', :controller => 'adsprints', via: %i(get post put patch delete)
match 'adtaskinl/(:action(/:id))', :controller => 'adtaskinl', via: %i(get post put patch delete)
match 'adtasks/(:action(/:id))', :controller => 'adtasks', via: %i(get post put patch delete)
match 'all_sprints/(:action(/:id))', :controller => 'all_sprints', via: %i(get post put patch delete)

match 'adtaskinl/inplace', :controller => 'adtaskinl', via: %i(get post put patch delete)
