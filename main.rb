require 'csv'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'bcrypt'
require './users'


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
  erb :login
end

get '/upload_users' do
  erb :upload_users
end

post '/login' do
  user = User.first(name:params[:username])
  if (user && BCrypt::Password.new(user.password) == params[:password])

    puts 'FOUND'
    if(user.role == "TA\n" || user.role == "Instructor\n")

      session[:admin] = true
    else
      session[:student] = true
    end
    redirect to ('/')
  else
      print "NOT FOUND #{params[:username]}"
  end

    erb :login
end

get '/logout' do
  session.clear
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
  redirect to ('/')
end


get '/report' do
  halt(401, 'Not Authorized') unless session[:admin]

  #Create the CSV file
  CSV.open('report.csv', 'wb') do |csv|
    users = User.all
    i =0
    while(i<users.size)
      #add students to report
      if users[i].role == "Student\n"
        csv << [users[i].name]

      end
      i+=1
    end
  end
  #Download the file
  send_file("report.csv")
  redirect to ('/')
end


not_found do
  erb :not_found
end
