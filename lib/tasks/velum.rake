# rubocop:disable Metrics/BlockLength
namespace :velum do
  desc "Create a user"
  task :create_user, [:email, :password] => :environment do |_, args|
    if args.count != 2
      puts "There are 2 required arguments: email and password"
      exit(-1)
    end

    args.each do |k, v|
      if v.empty?
        puts "You have to provide a value for `#{k}'"
        exit(-1)
      end
    end

    begin
      User.create! email: args["email"], password: args["password"]
      puts "User #{args["email"]} created successfully"
    rescue ActiveRecord::RecordInvalid
      puts "User #{args["email"]} could not be created. Does it already exist?"
    end
  end

  desc "Migrate database users to LDAP"
  task migrate_users: :environment do
    User.where.not(encrypted_password: [nil, ""]).each do |user|
      begin
        user.send :create_ldap_user
        puts "#{user.email} has been binded to LDAP (or is already bound)"
      rescue StandardError => e
        puts "Could not bind #{user.email} to LDAP. Reason: #{e}"
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
