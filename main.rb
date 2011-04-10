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
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite3://",settings.root, "development.db"))

########### Models ###########
class Card
  include DataMapper::Resource
  property :id,           Serial
  property :salt,         Text, :default => rand(9).to_s << (1+rand(8)).to_s
  property :design_id,    Integer
  property :title,        Text
  property :message,      Text
  property :sent_at,      DateTime
  property :from,         Text
  property :to,           Text
  property :email,        Text
  
  def url ; '/' + (id.to_s << salt).reverse.to_i.to_s(36) ; end
  
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

###########  Routes ###########
not_found { haml :'404' }
error { @error = request.env['sinatra_error'] ; haml :'500' }

get '/styles.css' do
  content_type 'text/css', :charset => 'utf-8'
  cache_control :public, :must_revalidate, :max_age => 60*60*24, :vary => 'Accept-Encoding'
  last_modified(File.mtime(__FILE__))
  scss :styles
end

get '/' do
  #greetings = %w[Hi Hello Hola Hallo Ciao Sawubona Ola Szervusz Howdy Bonjour]
  #@greeting = greetings[rand(greetings.size)]
  haml :index
end

get '/card/:id' do
  @card = Card.new(:design_id => params[:id])
  @design = ("design" + params[:id]).to_sym
  haml :new
end

post '/send' do
  if params['bot']['message']=='D2'&&params['bot']['email'].empty?
    @card = Card.create(params[:card].merge({:sent_at => Time.now}))
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
  @design = ("design" + @card.design_id.to_s).to_sym
  haml :card
end
__END__
########### Views ###########
@@404
%h3 That page seems to be lost in the clouds!

@@500
%h3 Oops ... there was and error, it was:
%p= @error
   
@@design1
-if @card.title
  %h1.title.snow= @card.title
-else
  %input.title.snow(value="Let It Snow! Let It Snow!" type="text" name="card[title]")
%img{:src=>settings.images+'/snowman.png'}

@@design2
-if @card.title
  %h1.title.robin= @card.title
-else
  %input.title.robin(value="Rocking Robins!" type="text" name="card[title]")
%img{:src=>settings.images+'/robins.png'}

@@design3
-if @card.title
  %h1.title.hippo= @card.title
-else
  %textarea.title.hippo(value="Hippo Birthday!" type="text" name="card[title]")Hippo Birthday!
%img{:src=>settings.images+'/hippo.png'}

@@design4
-if @card.title
  %h1.title.croc= @card.title
-else
  %input.title.croc(value="Snappy Birthday!" type="text" name="card[title]")
%img{:src=>settings.images+'/croc.png'}

@@design5
-if @card.title
  %h1.title.fish= @card.title
-else
  %input.title.fish(value="Birthday Fishes!" type="text" name="card[title]")
%img{:src=>settings.images+'/fish.png'}

@@design6
-if @card.title
  %h1.title.cake= @card.title
-else
  %input.title.cake(value="Birthday Cupcakes!" type="text" name="card[title]")
%img{:src=>settings.images+'/cupcake.png'}

@@design7
-if @card.title
  %h1.title.duck= @card.title
-else
  %input.title.duck(value="Quacky Birthday!" type="text" name="card[title]")
%img{:src=>settings.images+'/duck.png'}

@@design8
-if @card.title
  %h1.title.babyboy= @card.title
-else
  %input.title.babyboy(value="A New Baby Boy!" type="text" name="card[title]")
%img{:src=>settings.images+'/babyboy.png'}

@@design9
-if @card.title
  %h1.title.babygirl= @card.title
-else
  %input.title.babygirl(value="A New Baby Girl!" type="text" name="card[title]")
%img{:src=>settings.images+'/babygirl.png'}

@@design10
-if @card.title
  %h1.title.easter= @card.title
-else
  %input.title.easter(value="Happy Easter!" type="text" name="card[title]")
%img{:src=>settings.images+'/easter.png'}
