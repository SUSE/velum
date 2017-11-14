# rubocop:disable Metrics/BlockLength
namespace :velum do
  desc "Create a user"
  task :create_user, [:email, :password] => :environment do |_, args|
    validate_args(args, [:email, :password])
    begin
      User.create! email: args["email"], password: args["password"]
      puts "User #{args["email"]} created successfully"
    rescue ActiveRecord::RecordInvalid
      puts "User #{args["email"]} could not be created. Does it already exist?"
    end
  end

  desc "Create a pillar"
  task :create_pillar, [:pillar, :value] => :environment do |_, args|
    validate_args(args, [:pillar, :value])
    begin
      Pillar.create! args.to_hash
    rescue ActiveRecord::RecordInvalid => e
      puts "Pillar '#{args["pillar"]}' could not be created: "
      puts e.message
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

  def validate_args(args, expected_keys)
    if args.count != expected_keys.length
      puts [
        "There are ",
        ActionController::Base.helpers.pluralize(
          expected_keys.length,
          "required argument"
        ),
        ": ",
        expected_keys.to_sentence,
        "."
      ].join
      exit(-1)
    end
    args.each do |k, v|
      if v.empty?
        puts "You have to provide a value for `#{k}'."
        exit(-1)
      end
    end
  end

end
# rubocop:enable Metrics/BlockLength
