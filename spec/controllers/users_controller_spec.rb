require 'spec_helper'

describe UsersController do
  render_views

  describe "GET 'show'" do
    
    before(:each) do
      @user = Factory(:user)
    end
    
  end

  describe "GET 'new'" do
    it "should be successful" do
      get 'new'
      response.should be_success
    end

    it "should have the right title" do
      get 'new'
      response.should have_selector("title", :content => "Home")
    end

    it "should have a city field" do
      get :new
      response.should have_selector("input[name='user[city]'][type='text']")
    end

    it "should have a keywords field" do
      get :new
      response.should have_selector("input[name='user[keywords]'][type='text']")
    end

    it "should have a dates field" do
      get :new
      response.should have_selector("input[name='user[dates]'][type='text']")
    end

  end

  describe "POST 'create'" do
    
    describe "failure" do
      
      before "failure" do
        @attr = { :city => "", :keywords => "", :dates => "" }
      end
    
      it "should not create a user" do
        lambda do
          post :create, :user => @attr
        end.should_not change(User, :count)
      end

      it "should have the right title" do
        post :create, :user => @attr
        response.should have_selector("title", :content => "Home")
      end
      
      it "should render the 'new' page" do
        post :create, :user => @attr
        response.should render_template('new')
      end
      
    end
    
    describe "success" do
      
      before(:each) do
        @attr = { :city => "Boston", :keywords => "Jazz", 
                  :dates => "Today" }
      end
      
      it "should create a user" do
        lambda do
          post :create, :user => @attr
        end.should change(User, :count).by(1)
      end
      
      it "should redirect to the results page" do
        post :create, :user => @attr
        response.should redirect_to(results_path)
      end
    end
  end
end
