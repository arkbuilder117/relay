module Identity
  module Services
    class AuthenticationService
      def authenticate(email:, password:)
        user = User.find_by(email: email.to_s.downcase)
        user&.authenticate(password) ? user : nil
      end
    end
  end
end
