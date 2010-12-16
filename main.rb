########### Libraries ###########
%w[rubygems sinatra data_mapper haml sass pony digest/sha2].each{ |lib| require lib }

########### Configuration ###########
set :name, ENV['name'] || 'Cards in the Cloud'
set :author, ENV['author'] || 'DAZ'
set :salt, ENV['SALT'] || 'makethisrandomandhardtoremember'
set :password, ENV['PASSWORD'] || 'secret'
set :haml, { :format => :html5 }
set :public, Proc.new { root }

########### Models ###########
DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite3://",settings.root, "development.db"))
class Card
  include DataMapper::Resource
  property :id,           Serial
  property :message,      Text, :required => true
  property :secret_key,   Text, :default => Proc.new { |r, p| Digest::SHA2.hexdigest(r.message + Time.now.to_s) }
  property :design,       String
  def url
    '/' + self.secret_key 
  end
end
DataMapper.auto_upgrade!

###########  Admin ###########
helpers do
	def admin? ; request.cookies[settings.author] == settings.token ; end
	def protected! ; halt [ 401, 'Not authorized' ] unless admin? ; end
end
get('/admin'){ haml :admin }
post '/login' do
	response.set_cookie(settings.author, settings.token) if params[:password] == settings.password
	redirect '/'
end
get('/logout'){ response.set_cookie(settings.author, false) ; redirect '/' }

########### Helpers ###########
helpers do
# custom helpers go here
end

###########  Routes ###########
not_found { haml :'404' }
get('/styles.css'){ content_type 'text/css', :charset => 'utf-8' ; scss :styles }
get('/application.js') { content_type 'text/javascript' ; render :str, :js, :layout => false }

# home
get '/' do
  greetings = %w[Hi Hello Hola Hallo Ciao Sawubona Merhaba Labdien Ola Szervusz Howdy]
  @greeting = greetings[rand(greetings.size)]
  haml :index
end

get '/new' do
  haml :new
end

post '/send' do
  card = Card.create(params[:card])
  params[:email].split(",").each do |email|
    Pony.mail(
      :from => settings.name,
      :to => email,
      :subject => params[:from] + " has sent you a card",
      :body => haml(:email,{ :layout=>false,:locals => { :card => card } }),
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
  redirect card.url
end

get '/:key' do
  card = Card.first(:secret_key => params[:key])
  raise error(404) unless card
  @message = card.message
  haml :xmas
end
__END__
########### Views ###########
@@layout
!!! 5
%html
  %head
    %meta(charset="utf-8")
    %title= @title || settings.name
    %link(rel="stylesheet" media="screen, projection" href="/reset.css")
    %link(rel="stylesheet" media="screen, projection" href="/styles.css")
    %script(src="http://rightjs.org/hotlink/right.js")
    %script(src="/application.js")
    /[if lt IE 9]
      %script(src="http://html5shiv.googlecode.com/svn/trunk/html5.js")
  %body{:id => settings.name, :class => @title || settings.name}
    %header(role="banner")
      %h1 <a title="home" href="/">#{ settings.name }</a>
    = yield

@@admin
%form(action="/login" method="post")
  %input(type="password" name="password")
  %input(type="submit" value="Login") or <a href="/">Cancel</a>
  
@@index
%h1= @greeting + "!"
%p Welcome to #{settings.name}. The easiest way to send an electronic greetings card to your friends and family.
%a(href="/new")Send a xmas card

@@new
#card
  %h1 Let It Snow! Let It Snow!
  %img(src="/snowman.png")
%form(action="/send" method="post")
  %label(for="to")To:<input type="text" name="to" id="to">
  %label(for="email")Email:<input type="text" name="email" id="email">
  %textarea#message(name="card[message]")Write your message here...
  %label(for="from")From:<input type="text" name="from" id="from">
  %input#send(type="submit" value="Send")
  
@@email
:plain
  Hi #{params[:to]}. You've been sent an eCard from #{params[:from]}. You can see your card here http://#{env['HTTP_HOST']+card.url}
  
@@xmas
#card
  #front
    %h1 Let It Snow! Let It Snow!
    %img(src="/snowman.png")
  #message
    =@message
%footer(role="contentinfo")
  %small This card was brought to you by <a href="/">#{settings.name}</a>
      
@@404
%h3 Sorry, but that page cannot be found

@@js
// javascript goes here

@@styles
@import url("http://fonts.googleapis.com/css?family=Just+Me+Again+Down+Here|Raleway:100|Mountains+of+Christmas&subset=latin");
$bg: #fff;$color: #666;
$primary: #619FEA;$secondary:#1757A4;
$font: "Droid serif",Times,"Times New Roman",serif;
$hcolor: $primary;$hfont: "Raleway",sans-serif;
$hbold: false;
$acolor:$primary;$ahover:$secondary;$avisited:lighten($acolor,10%);

html, body, div, span, object, iframe,h1, h2, h3, h4, h5, h6, p, blockquote, pre,abbr, address, cite, code,del, dfn, em, img, ins, kbd, q, samp,small, strong, sub, sup, var,b, i,dl, dt, dd, ol, ul, li,fieldset, form, label, legend,table, caption, tbody, tfoot, thead, tr, th, td,article, aside, canvas, details, figcaption, figure, footer, header, hgroup, menu, nav, section, summary,time, mark, audio, video{ margin: 0;padding: 0;border: 0;outline: 0;font-size: 100%;vertical-align: baseline;background: transparent; }
article,aside,canvas,details,figcaption,figure,
footer,header,hgroup,menu,nav,section,summary{ display: block; }
body{ font-family: $font;background-color: $bg;color: $color; }
h1,h2,h3,h4,h5,h6{ color: $hcolor;font-family: $hfont;@if $hbold { font-weight: bold; } @else {font-weight: normal;}}
h1{font-size:4.2em;}h2{font-size:3em;}h3{font-size:2.4em;}
h4{font-size:1.6em;}h5{font-size:1.2em;}h6{font-size:1em;}
p{font-size:1.2em;line-height:1.5;margin:1em 0;max-width:40em;}
li{font-size:1.2em;line-height:1.5;}
a,a:link{color:$acolor;}
a:visited{color:$avisited;}
a:hover{color:$ahover;text-decoration:none;}
img{max-width:100%;_width:100%;display:block;margin:0 auto;}

header{background:$primary;border-bottom:5px solid $secondary;
a,a:link,a:visited{color:#fff;text-decoration:none;}
h1{
text-transform:uppercase;
font-size:24px;
text-align:right;
}}

#message{
  padding:20px 10px;margin:0;
  background: #fff url(paper.jpg);border:5px solid #ccc;
  font-size: 32px;
  font-family:'Just Me Again Down Here',sans-serif;
  text-align:center;
  min-height:4em;_height:4em;
  width:12em;
  margin: 10px auto;
}


footer{clear:both;margin-top:40px;}

#card h1{
  font-size: 64px;
  font-family:'Mountains of Christmas',serif;
  color:#F04137;
  text-shadow: 1px 1px 0 green;
  text-align:center;
  position:relative;top:1.6em;
  font-weight:bold;
}
#card img{max-width:100%;display:block;margin: 0 auto;}


form{float:left;margin-left:50px;position:relative;padding-bottom:4em;
label{display:block;margin:10px auto;font-size:60px;font-family:'Reenie Beanie', serif;;color:#999;}
input{font-size:24px;font-family:verdana,sans-serif;}
input#to{position:relative;left:3.4em;}
input#email{position:relative;left:1.0em;}
input#from{position:relative;left:1.7em;}
}
#send{font-size:48px;background:#f04137;color:#fff;border:none;border-radius:12px;position:absolute;bottom:0;right:0;}
