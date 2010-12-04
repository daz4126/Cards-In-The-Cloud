########### Libraries ###########
%w[rubygems sinatra data_mapper haml sass pony moonshado-sms].each{ |lib| require lib }

########### Configuration ###########
set :name, ENV['name'] || 'eCards'
set :author, ENV['author'] || 'DAZ'
set :token, ENV['TOKEN'] || 'makethisrandomandhardtoremember'
set :password, ENV['PASSWORD'] || 'secret'
set :haml, { :format => :html5 }
set :public, Proc.new { root }

Moonshado::Sms.configure do |config|
    config.api_key = ENV['MOONSHADOSMS_URL']
end

########### Models ###########
DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite3://",settings.root, "development.db"))
class Card
  include DataMapper::Resource
  property :id,           Serial
  property :message,      Text, :required => true
  property :design,       String
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
  greetings = %w[Hi Hello Hola Hallo Ciao Sawubona Merhaba Labdien Ola Szervusz]
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
  redirect '/card/' + card.id.to_s
end

get '/card/:id' do
  @message = Card.get(params[:id]).message
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
  %h1 Merry Xmas!
  %img(src="/freexmas.png")
%form(action="/send" method="post")
  %label(for="to")To:<input type="text" name="to" id="to">
  %label(for="email")Email:<input type="text" name="email" id="email">
  %textarea#message(name="card[message]")Write your message here...
  %label(for="from")From:<input type="text" name="from" id="from">
  %input#send(type="submit" value="Send")
  
@@email
:plain
  Hi #{params[:to]}. You've been sent an eCard from #{params[:from]}. You can see your card here http://ecards.heroku.com/card/#{card.id}
  
@@xmas
#card
  #front
    %h1 Merry Xmas!
    %img(src="/freexmas.png")
  #message
    =@message
%footer(role="contentinfo")
  %small This card was brought to you by <a href="/">#{settings.name}</a>
      
@@404
%h3 Sorry, but that page cannot be found

@@js
// javascript goes here

@@styles
@import url("http://fonts.googleapis.com/css?family=Reenie+Beanie|Lobster&subset=latin");
$bg: #fff;$color: #666;
$primary: red;$secondary: blue;
$font: "Droid serif",Times,"Times New Roman",serif;
$hcolor: $primary;$hfont: "Droid sans",sans-serif;
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

header{background:#A3A8AB;border-bottom:5px solid #ccc;
h1{
font-family:verdana,sans;
text-transform:uppercase;
font-size:24px;
text-align:right;
}}

#message{
  padding:20px 10px;margin:0;
  background: #fff url(paper.jpg);border:5px solid #ccc;
  font-size: 32px;
  font-family:'Reenie Beanie',sans-serif;
  text-align:center;
  min-height:4em;_height:4em;
  width:12em;
}

#card{overflow:hidden;margin:0 auto;float:left;margin-left:20px;
}

footer{clear:both;}

#card h1{
  font-size: 48px;
  font-family:Lobster,serif;
  color:#F04137;
  text-align:center;
}
form{float:left;margin-left:50px;position:relative;padding-bottom:4em;
label{display:block;margin:10px auto;font-size:60px;font-family:'Reenie Beanie', serif;;color:#999;}
input{font-size:24px;font-family:verdana,sans-serif;}
input#to{position:relative;left:3.4em;}
input#email{position:relative;left:1.0em;}
input#from{position:relative;left:1.7em;}
}
#send{font-size:48px;background:#f04137;color:#fff;border:none;border-radius:12px;position:absolute;bottom:0;right:0;}
