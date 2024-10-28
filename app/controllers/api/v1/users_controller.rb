module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :doorkeeper_authorize!, only: [ :create, :login ]
      before_action :set_user, only: %i[ show update destroy ]

      def index
        @users = User.all
        render json: { users: @users, message: "Users fetched successfully." }, status: :ok
      end

      def show
        render json: { user: @user, message: "Specific user fetched successfully." }, status: :ok
      end

      def update
        if @user
          @user.update(user_params)
          render json: { user: @user, message: "User #{@user.first_name} updated successfully." }, status: :ok
        else
          render json: { error: "User not found" }, status: :not_found
        end
      end

      def destroy
        if @user
          @user.destroy
          render json: { message: "User #{@user.first_name} deleted successfully." }, status: :ok
        else
          render json: { error: "User not found" }, status: :not_found
        end
      end

      def create
        user = User.new(user_params)
        client_app = Doorkeeper::Application.find_by(uid: params[:client_id])

        unless client_app
          return render json: { error: "Invalid client ID" }, status: 403
        end

        if user.save
          access_token = Doorkeeper::AccessToken.create(
            resource_owner_id: user.id,
            application_id: client_app.id,
            refresh_token: generate_refresh_token,
            expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
            scopes: ""
          )

          render json: {
            message: "User created successfully.",
            user: {
              id: user.id,
              email: user.email,
              role: user.first_name,
              mobile_no: user.mobile_no,
              date_of_birth: user.date_of_birth,
              gender: user.gender,
              first_name: user.surname,
              access_token: access_token.token,
              token_type: "bearer",
              expires_in: access_token.expires_in,
              refresh_token: access_token.refresh_token,
              created_at: access_token.created_at.to_time.to_i
            }
          }, status: 201
        else
          render json: { error: user.errors.full_messages }, status: 422
        end
      end

      def login
        login_identifier = params[:user][:login_type]
        user = User.find_for_authentication(email: login_identifier) ||
               User.find_for_authentication(mobile_number: login_identifier)

        if user.nil?
          render json: { error: "User not found" }, status: :not_found
          return
        end

        if user.valid_password?(params[:user][:password])
          client_app = Doorkeeper::Application.find_by(uid: params[:client_id])
          access_token = Doorkeeper::AccessToken.create(
            resource_owner_id: user.id,
            application_id: client_app.id,
            refresh_token: generate_refresh_token,
            expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
            scopes: ""
          )

          render(json: {
            message: "User login successfully",
            user: {
              id: user.id,
              email: user.email,
              role: user.first_name,
              mobile_no: user.mobile_no,
              date_of_birth: user.date_of_birth,
              gender: user.gender,
              first_name: user.surname,
              access_token: access_token.token,
              token_type: "bearer",
              expires_in: access_token.expires_in,
              refresh_token: access_token.refresh_token,
              created_at: access_token.created_at.to_time.to_i
            }
          })
        else
          render json: { error: "Invalid email/mobile number or password" }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :surname, :email, :password, :date_of_birth, :gender, :mobile_no)
      end

      def set_user
        @user = User.find(params[:id])
      end

      def generate_refresh_token
        loop do
          token = SecureRandom.hex(32)
          break token unless Doorkeeper::AccessToken.exists?(refresh_token: token)
        end
      end
    end
  end
end
