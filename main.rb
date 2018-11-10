require 'csv'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'bcrypt'

require 'zip/zip'

require './users'

session_username = ""

configure do
  enable :sessions

  #TODO get users from database
  #tmp = User.all
  #for el in tmp do
  #  puts "setting #{el.name}"
  #  set :username, el.name
  #  set :password, BCrypt::Password.new(el.password)
  #  set :role, el.role
  #end
end

get '/' do
  erb :home
end

#save the file in public folder
post '/save_file' do
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]
  File.open("./public/#{@filename}", 'wb') do |f|
    f.write(file.read)
  end
  addUsers(@filename)
  redirect to ('/')
end

get '/login' do
  if session[:student] || session[:admin]
    halt(401, 'Not Authorized')
  end
  erb :login
end

get '/upload_users' do
  erb :upload_users
end

@tries = 0
post '/login' do
  if session[:student] || session[:admin]
    halt(401, 'Not Authorized')
  end
  user = User.first(name:params[:username])
  if (user && BCrypt::Password.new(user.password) == params[:password])
    puts 'FOUND'
    session_username= user.name
    if(user.role == "TA\n" || user.role == "Instructor\n")

      session[:admin] = true
    else
      session[:student] = true
    end
    puts "TRIES AE #{@tries}"
    erb :home
  else
      print "NOT FOUND #{params[:username]}"
      @tries = 1
      puts "TRIES AE #{@tries}"
      erb :login
  end



end

get '/logout' do
  session.clear
  session_username =""
  @tries = 0
  redirect to('/login')
end

get '/upload_websites' do
  halt(401, 'Not Authorized') unless session[:admin]
  erb :upload_websites
end


post '/upload_websites' do
  halt(401, 'Not Authorized') unless session[:admin]
  @filename = params[:file][:filename]
  file = params[:file][:tempfile]
  File.open("./public/#{@filename}", 'wb') do |f|
    f.write(file.read)
  end

  unzip_file( file,"./public/websites")

  redirect to ('/')
end


post '/vote' do
  halt(401, 'Not Authorized') unless session[:student]
  #TODO Check if student already voted
  if (params[:vote1]== params[:vote2] || params[:vote1] == params[:vote3] || params[:vote2] == params[:vote3])
    print "Voting for the same site in different categories"
  end

  user = User.first(name: session_username)
  print user.name

  if(user.voted == 'NO')
    user.update(:voted => 'YES', :vote1 => params[:vote1], :vote2 => params[:vote2], :vote3 =>params[:vote3])
    redirect to ('/')
  else
    print "USER VOTED"
    redirect to ('/restaurants')
  end

end

get '/report' do
  halt(401, 'Not Authorized') unless session[:admin]
  @voters = []
  #Create the CSV file
  CSV.open('report.csv', 'wb') do |csv|
    users = User.all
    i =0
    while(i<users.size)
      #add students to report
      if users[i].role == "Student\n"
        if users[i].voted == 'NO'
          tmp = users[i].name + '   Voted: '+ users[i].voted
        else
          tmp = users[i].name + '   Voted: '+ users[i].voted + ' First Place: ' + users[i].vote1 + ' Second Place: ' + users[i].vote2 + ' Third Place: ' + users[i].vote3
        end


        @voters.push(tmp)

        csv << [users[i].name, users[i].voted, users[i].vote1, users[i].vote2, users[i].vote3]
      end
      i+=1
    end
  end
  erb :report

end

get '/report/download' do
  halt(401, 'Not Authorized') unless session[:admin]
  @voters = []
  #Create the CSV file
  CSV.open('report.csv', 'wb') do |csv|
    users = User.all
    i =0
    while(i<users.size)
      #add students to report
      if users[i].role == "Student\n"
        @voters.push(users[i].name)

        csv << [users[i].name, users[i].voted, users[i].vote1, users[i].vote2, users[i].vote3]
      end
      i+=1
    end
  end
  #Download the file
  send_file("report.csv", :type => 'txt/csv', :disposition => 'attachment')
  redirect to ('/')
end


get '/restaurants' do
  #Get restaurants path
  @restaurants =  Dir["public/websites/*.html"]
  print @restaurants
  erb :restaurants
end

get '/restaurants/public/websites/:file' do
  #Open a restaurant website from the websites folder
  File.read("public/websites/#{params[:file]}")
end

not_found do
  erb :not_found
end


#Unzip function from https://gist.github.com/Amitesh/1247229
#Used to unzip the websites file uploaded by the admin
def unzip_file (file, destination)
  Zip::ZipFile.open(file) { |zip_file|
    zip_file.each { |f|
      f_path=File.join(destination, f.name)
      FileUtils.mkdir_p(File.dirname(f_path))
      zip_file.extract(f, f_path) unless File.exist?(f_path)
    }
  }
end