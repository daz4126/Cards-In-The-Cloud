########### Libraries ###########
%w[rubygems sinatra dm-core dm-migrations haml sass pony].each{ |lib| require lib }

########### Configuration ###########
set :name,'Cards in the Cloud'
set :images, 'http://pics.cardsinthecloud.com'
set :analytics, ENV['ANALYTICS'] || 'UA-XXXXXXXX-X'
set :haml, { :format => :html5 }

configure :development do
  set :domain,'localhost:9393'
end

configure :test do
  # test stuff here
end

configure :production do
  set :domain,'cardsinthecloud.com'
  set :scss, { :style => :compressed }
end

########### Models ###########
DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite3://",settings.root, "development.db"))
class Card
  include DataMapper::Resource
  property :id,           Serial
  property :message,      Text
  property :secret_key,   Text, :default => Proc.new { |r, p| (r.id.to_s+rand(9).to_s+(1+rand(8)).to_s).reverse.to_i.to_s(36) }
  property :design_id,    Integer
  def url ; '/' + self.secret_key ; end
end
DataMapper.auto_upgrade!

###########  Routes ###########
not_found { haml :'404' }
error { @error = request.env['sinatra_error'] ; haml :'500' }
get('/styles.css'){ content_type 'text/css', :charset => 'utf-8' ; scss :styles }

get '/' do
  #greetings = %w[Hi Hello Hola Hallo Ciao Sawubona Ola Szervusz Howdy Bonjour]
  #@greeting = greetings[rand(greetings.size)]
  haml :index
end

get '/card/:id' do
  @design_id = params[:id]
  @design = ("design" + params[:id]).to_sym
  haml :new
end

post '/send' do
  @card = Card.create(params[:card])
  @receiver = params[:to]
  @sender = params[:from]
  @email = params[:email]
  @email.split(",").each do |email|
    Pony.mail(
      :from => 'Cards in the Cloud<info@cardsinthecloud.com>',
      :to => email,
      :subject => @sender + " has sent you a card",
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
      #Need to figure out how to log cards sent
      #LOG.info "Card sent to #{email} by #{params[:from]}"
    end
  haml :sent
end

get '/:key' do
  card = Card.first(:secret_key => params[:key])
  raise error(404) unless card
  @message = card.message
  @design = ("design" + card.design_id.to_s).to_sym
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
%h1.title.snow Let It Snow! Let It Snow!
%img{:src=>settings.images+'/snowman.png'}

@@design2
%h1.title.robin Rocking Robins!
%img{:src=>settings.images+'/robins.png'}

@@design3
%h1.title.hippo Hippo Birthday!
%img{:src=>settings.images+'/hippo.png'}

@@design4
%h1.title.croc Snappy Birthday!
%img{:src=>settings.images+'/croc.png'}

@@design5
%h1.title.fish Birthday Fishes!
%img{:src=>settings.images+'/fish.png'}

@@design6
%h1.title.cake Happy Birthday!
%img{:src=>settings.images+'/cupcake.png'}

@@design7
%h1.title.duck Quacky Birthday!
%img{:src=>settings.images+'/duck.png'}

@@design8
%h1.title.babyboy A New Baby Boy!
%img{:src=>settings.images+'/babyboy.png'}

@@design9
%h1.title.babygirl A New Baby Girl!
%img{:src=>settings.images+'/babygirl.png'}
