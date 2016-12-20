ActiveAdmin.register Client do
  permit_params :client_name, :email, :password

  index do
    id_column
    column :client_name
    column :email
    column :api_key
    column :secret_key
    column :created_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :client_name
      f.input :email
      f.input :password
    end
    f.actions
  end

  controller do
    # This code is evaluated within the controller class
    def create
      @client = Client.new(permitted_params[:client])
      super
    end
  end

end
