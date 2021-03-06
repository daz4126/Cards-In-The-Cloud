%w[rubygems sinatra dm-core dm-migrations haml sass pony].each{ |lib| require lib }

########### Configuration ###########
set :name,'Cards in the Cloud'
set :images, 'http://pics.cardsinthecloud.com'
set :email, 'daz4126@gmail.com'
set :analytics, ENV['ANALYTICS'] || 'UA-XXXXXXXX-X'
set :haml, { :format => :html5 }

configure :development do
  # development config here
end

configure :test do
  # test config here
end

configure :production do
  set :scss, { :style => :compressed }
  set :haml, { :ugly => true }
  sha1, date = `git log HEAD~1..HEAD --pretty=format:%h^%ci`.strip.split('^') 
  before do
    cache_control :public, :must_revalidate, :max_age => 60*60*24*7
    etag sha1
    last_modified date
  end
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite3://",settings.root, "development.db"))

########### Cards ###########
class Card
  include DataMapper::Resource
  property    :id,           Serial
  property    :salt,         String, :default =>  proc { (1+rand(8)).to_s}
  property    :title,        String, :length => 256
  property    :message,      Text
  property    :created_at,   DateTime, :default =>  proc { Time.now}
  property    :from,         String, :length => 128
  property    :to,           String, :length => 128
  property    :email,        String, :length => 128
  property    :sender_email, String, :length => 128
  property    :css,          String, :default =>  proc { |r,p| r.design.css }
  belongs_to  :design
  
  def url
    '/' + (id.to_s + salt).reverse.to_i.to_s(36)
  end
  
  # expires after 30 days
  def expires
    created_at + 30
  end
  
  def self.send_daily_stats
    @cards = self.all(:created_at => ((Time.now - 24*60*60)..Time.now))
    Pony.mail(
      :from => 'Cards in the Cloud<donotreply@cardsinthecloud.com>',
      :to => settings.email,
      :subject => "Cards sent Today",
      :body => "#{@cards.count} card(s) were sent in the cloud today",
      :port => '587',
      :via => :smtp,
      :via_options => { 
        :address              => ENV['SENDGRID_ADDRESS']||'smtp.gmail.com', 
        :port                 => '587', 
        :enable_starttls_auto => true, 
        :user_name            => ENV['SENDGRID_USERNAME']||'daz4126', 
        :password             => ENV['SENDGRID_PASSWORD']||'topsecret', 
        :authentication       => :plain, 
        :domain               => ENV['SENDGRID_DOMAIN']||'localhost.localdomain'
      })
  end
  
  def self.stats(days=30)
    self.all(:created_at => ((Time.now - days*24*60*60)..Time.now)).count
  end
end

########### Designs ###########
class Design
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  property :title,        String
  property :image,        String
  property :css,          Text
  property :type,         String
  property :alt,          String
  has n, :cards
end

DataMapper.finalize

###########  email helper ###########

helpers do

def email(opts = {} )
  to = opts[:to] || settings.email
  Pony.mail(
    :from => opts[:from],
    :to => to,
    :subject => opts[:subject],
    :html_body => opts[:body],
    :port => '587',
    :via => :smtp,
    :via_options => { 
      :address              => ENV['SENDGRID_ADDRESS']||'smtp.gmail.com', 
      :port                 => '587', 
      :enable_starttls_auto => true, 
      :user_name            => ENV['SENDGRID_USERNAME']||'daz4126', 
      :password             => ENV['SENDGRID_PASSWORD']||'senior6DJ!', 
      :authentication       => :plain, 
      :domain               => ENV['SENDGRID_DOMAIN']||'localhost.localdomain'
    })
end

end

###########  Routes ###########
not_found { @title='Card Missing' ; haml :'404' }
error { @error = request.env['sinatra_error'].name ; haml :'500' }

class Expired < StandardError; end

error Expired do
  haml :expired
end

get('/styles.css'){ scss :styles }
get('/application.js') { coffee :application }

get '/' do
  @title='Cards in the Cloud - the easy way to send personalized e-cards'
  @categories = %w(Christmas Birthday Good\ Luck Baby Easter Halloween)
  haml :index
end

get '/card/:id' do
  design = Design.get(params[:id])
  @card = design.cards.new
  @title = design.title
  haml :new
end

get '/feedback' do
  @title = 'FeedBAAck'
  haml :feedback
end

post '/feedback' do
  #if params['bot']['message']=='D2'&&params['bot']['email'].empty?
    email :from => "#{params[:from]}<#{params[:email]}>",
          :body => params[:message], 
          :subject => "Cards in the Cloud FeedBAAck"
#  else
#    halt [ 401, 'Get Lost Spam Bot!' ]
#  end
  haml :sent
end

post '/send' do
  if params['bot']['message']=='D2'&&params['bot']['email'].empty?
    css = {css: "color:#{params['color']};font-size:#{params['font-size']}px;"}
    @card = Design.get(params[:id]).cards.create(params[:card].merge(css))
    @card.email.split(",").each do |e|
      email :from =>"#{settings.name}<donotreply@cardsinthecloud.com>",
            :to => e,
            :subject => @card.from + " has sent you a card",
            :body => haml(:email,{ :layout=>false,:locals => { :card => @card } })
      end
  else
    halt [ 401, 'Get Lost Spam Bot!' ]
  end
  haml :sent
end

#get '/stats' do
#  @cards = Card.all
#  @title = settings.name + ' - statistics'
#  haml :stats
#end

get '/:shorturl' do
  id = params[:shorturl].to_i(36).to_s.reverse
  salt = id.slice!(-1,1)
  @card = Card.get(id)
  raise error(404) unless @card && salt == @card.salt
  raise error(404) if @card.expires < DateTime.now
  #raise Expired,'Card has Expired' if @card.created_at < Time.now
  @title = @card.title
  haml :card
end
__END__
########### Views ###########
@@404
%h1 Lost in the Clouds!
%p The card you're looking for seems to be missing.
%p Are you sure that you typed the web address correctly?

@@500
%h1 Crikey!
%p We're very sorry, but there's been an error:
%p= @error
%p We'll get it fixed so things are back up and running as soon as possible.

@@expired
%h1 That Card has expired!
%p Cards only stay in the cloud for a month.
