########### Libraries ###########
%w[rubygems sinatra dm-core dm-migrations haml sass pony].each{ |lib| require lib }

########### Configuration ###########
set :name,'Cards in the Cloud'
set :images, 'http://pics.cardsinthecloud.com'
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
  before do 
    cache_control :public, :must_revalidate, :max_age => 60*60*24*7
  end 
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite3://",settings.root, "development.db"))

########### Cards ###########
class Card
  include DataMapper::Resource
  property :id,           Serial
  property :salt,         Text, :default => rand(9).to_s + (1+rand(8)).to_s
  property :title,        Text
  property :message,      Text
  property :sent_at,      DateTime
  property :from,         Text
  property :to,           Text
  property :email,        Text
  belongs_to :design
  
  def url ; '/' + (id.to_s + salt).reverse.to_i.to_s(36) ; end
  
  def self.send_daily_stats
    @cards = self.all(:sent_at => ((Time.now - 24*60*60)..Time.now))
      Pony.mail(
        :from => 'Cards in the Cloud<donotreply@cardsinthecloud.com>',
        :to => 'daz4126@gmail.com',
        :subject => "Cards sent Today",
        :body => "#{@cards.count} card(s) were sent in the cloud today",
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

########### Designs ###########
class Design
  include DataMapper::Resource
  property :id,           Serial
  property :name,         Text
  property :title,        Text
  property :image,        Text
  property :css,          Text
  property :type,         Text
  property :alt,          Text
  has n, :cards
end

#Design.create(:name => 'croc',:title => 'Snappy Birthday!',:image => 'croc',:css => 'color:#ff6;',:type => 'birthday',:alt => 'A Hungry Crocodile');
#Design.create(:name => 'hippo',:title => 'Hippo Birthday!',:image => 'hippo',:css => 'color:#a02c2c;',:type => 'birthday',:alt => 'A Big Hippo');
#Design.create(:name => 'fish',:title => 'Birthday Fishes!',:image => 'fish',:css => 'color:#f6f;',:type => 'birthday',:alt => 'Fishes in the Sea');
#Design.create(:name => 'cupcake',:title => 'Birthday Cupcakes!',:image => 'cupcake',:css => 'color:#96f;',:type => 'birthday',:alt => 'Three Cupcakes');
#Design.create(:name => 'duck',:title => 'Quacky Birthday!',:image => 'duck',:css => 'color:#fcf;',:type => 'birthday',:alt => 'A Flying Duck');
#Design.create(:name => 'snowman',:title => 'Let It Snow!',:image => 'snowman',:css => 'color:#c00;text-shadow: 0.05em 0.05em 0 #050;',:type => 'xmas',:alt => 'A Snowman');
#Design.create(:name => 'robins',:title => 'Rocking Robins!',:image => 'robins',:css => 'color:#F7FB4A;text-shadow: 0.05em 0.05em 0 #F57B24;',:type => 'xmas',:alt => 'Three Robins');
#Design.create(:name => 'easter',:title => 'Happy Easter!',:image => 'easter',:css => 'color:#ff9955;text-shadow: 0.05em 0.05em 0 #4386eb;',:type => 'easter',:alt => 'The Easter Bunny with lots of Easter Eggs');
#Design.create(:name => 'babyboy',:title => 'Baby Boy!',:image => 'babyboy',:css => 'color:#fff;',:type => 'baby',:alt => 'A Baby Boy');
#Design.create(:name => 'babygirl',:title => 'Baby Girl!',:image => 'babygirl',:css => 'color:#fff;',:type => 'baby',:alt => 'A Baby Girl')


###########  Routes ###########
not_found { haml :'404' }
error { @error = request.env['sinatra_error'] ; haml :'500' }

get '/styles.css' do
  if settings.environment == :production
    cache_control :public, :must_revalidate, :max_age => 60*60*24*7, :vary => 'Accept-Encoding'
    last_modified(File.mtime(settings.views << '/styles.scss'))
  end
  content_type 'text/css', :charset => 'utf-8'
  scss :styles
end

get '/' do
  #greetings = %w[Hi Hello Hola Hallo Ciao Sawubona Ola Szervusz Howdy Bonjour]
  #@greeting = greetings[rand(greetings.size)]
  @birthday = Design.all(:type => 'birthday')
  @xmas = Design.all(:type => 'xmas')
  @easter = Design.all(:type => 'easter')
  @babies = Design.all(:type => 'baby')
  haml :index
end

get '/card/:id' do
  @card = Design.get(params[:id]).cards.new
  haml :new
end

post '/send' do
  if params['bot']['message']=='D2'&&params['bot']['email'].empty?
    @card = Design.get(params[:id]).cards.create(params[:card].merge({:sent_at => Time.now}))
    @card.email.split(",").each do |email|
      Pony.mail(
        :from => 'Cards in the Cloud<donotreply@cardsinthecloud.com>',
        :to => email,
        :subject => @card.from + " has sent you a card",
        :html_body => haml(:email,{ :layout=>false,:locals => { :card => @card } }),
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
  else
    halt [ 401, 'Not authorized' ]
  end
  haml :sent
end

get '/stats' do
  @cards = Card.all
  haml :stats
end

get '/:shorturl' do
  id = params[:shorturl].to_i(36).to_s.reverse
  salt = id.slice!(-2,2)
  @card = Card.get(id)
  raise error(404) unless @card && salt == @card.salt
  haml :card
end
__END__
########### Views ###########
@@404
%h1 Ooops!
%p Whatever you're looking for seems to be lost in the clouds. 
%p You might find a silver lining on the <a href='/'>homepage</a>.

@@500
%h3 Crikey!
%p We're very sorry, but there's been an error.
%p It seems that the error is:
%p= @error
