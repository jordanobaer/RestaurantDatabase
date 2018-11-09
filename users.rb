require 'dm-core'
require 'dm-migrations'

configure do
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
end

class User
  include DataMapper::Resource
  property :id, Serial
  property :name, String
  property :password, String
  property :role, String
  property :voted, String
end

DataMapper.finalize()



#Open the users.csv file and create the users in the database
def addUsers(filename)
  f = File.open("./public/#{@filename}", "r")
  #iterate through the csv file and create the users

  f.each_line do |line|
    info = line.split(",")
    info[1] = BCrypt::Password.create(info[1]) #Hash the password
    user = User.new
    user.name = info[0]
    user.password = info[1]
    user.role = info[2]
    #user.voted = nil
    user.save
    #print user
  end
  f.close


end