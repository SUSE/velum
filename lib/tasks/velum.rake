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
end
