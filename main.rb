########### Libraries ###########
%w[rubygems sinatra dm-core dm-migrations haml sass pony digest/md5].each{ |lib| require lib }

########### Configuration ###########
set :name,'Cards in the Cloud'
set :images, 'https://s3.amazonaws.com/cloudcards'
set :haml, { :format => :html5 }
set :public, Proc.new { root }

########### Models ###########
DataMapper.setup(:default, ENV['DATABASE_URL'] || File.join("sqlite3://",settings.root, "development.db"))
class Card
  include DataMapper::Resource
  property :id,           Serial
  property :message,      Text
  property :secret_key,   Text, :default => Proc.new { |r, p| Digest::MD5.hexdigest(r.message + Time.now.to_s) }
  property :design_id,    Integer
  def url
    '/' + self.secret_key 
  end
end
DataMapper.auto_upgrade!

###########  Routes ###########
not_found { haml :'404' }
get('/styles.css'){ content_type 'text/css', :charset => 'utf-8' ; scss :styles }

# home
get '/' do
  greetings = %w[Hi Hello Hola Hallo Ciao Sawubona Ola Szervusz Howdy Bonjour]
  @greeting = greetings[rand(greetings.size)]
  haml :index
end

get '/card/:id' do
  @design_id = params[:id]
  @design = ("design" + params[:id]).to_sym
  haml :new
end

post '/send' do
  card = Card.create(params[:card])
  params[:email].split(",").each do |email|
    Pony.mail(
      :from => "CloudCards",
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
      #Need to figure out how to log cards sent
      #LOG.info "Card sent to #{email} by #{params[:from]}"
    end
  redirect card.url
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
@@layout
!!! 5
%html
  %head
    %meta(charset='utf-8')
    %title= @title || settings.name
    %link(rel='shortcut icon' href='/favicon.ico')
    %link(rel='stylesheet' media="screen, projection" href='/styles.css')
    /[if lt IE 9]
      %script(src='http://html5shiv.googlecode.com/svn/trunk/html5.js')
  %body
    %header(role='banner')
      %h1 <a title='home' href='/' class='logo'>#{settings.name}</a>
    .content
      = yield
    %footer(role='contentinfo')
      %small <a href='/' class='logo'>#{settings.name}</a> is completely free to use. Why not make a <a href='http://uk.virginmoneygiving.com/giving/'>donation to charity</a> to say thank you?
  
@@index
%h1= @greeting+'!'
%p Welcome to #{settings.name}!
%p It's easy to send a card in the cloud to your friends and family. 
%p Just choose which card to send and click on the picture!
%h3 Birthday Cards
%ul.cards
  %li
    %h1.title Snappy Birthday!
    %a(href='/card/4')
      %img{:src=>settings.images+"/croc-th.png"}
  %li
    %h1.title Hippo Birthday
    %a(href='/card/3')
      %img{:src=>settings.images+"/hippo-th.png"}
      
  %li
    %h1.title Birthday Fishes
    %a(href='/card/5')
      %img{:src=>settings.images+"/fish-th.png"}

  %li
    %h1.title Birthday Cupcakes
    %a(href='/card/6')
      %img{:src=>settings.images+"/cupcake-th.png"}

%h3 Xmas Cards
%ul.cards
  %li
    %h1.title Let It Snow!
    %a(href='/card/1')
      %img{:src=>settings.images+"/snowman-th.png"}
  %li
    %h1.title Rocking Robins
    %a(href='/card/2')
      %img{:src=>settings.images+"/robins-th.png"}

@@new
#card
  =haml @design
%form(action="/send" method="post")
  %textarea#message(name="card[message]")Write your message here...
  %label(for="to")To:<input type="text" name="to" id="to">
  %label(for="email")Email:<input type="text" name="email" id="email">
  %label(for="from")From:<input type="text" name="from" id="from">
  %input(type="hidden" name="card[design_id]" value="#{@design_id}")
  %input#send(type="submit" value="Send")
  
@@email
:plain
  Hi #{params[:to]}. You've been sent a card in the cloud from #{params[:from]}. You can see your card here http://#{env['HTTP_HOST']+card.url}
  
@@card
#card
  =haml @design
#message
  =@message
      
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
 
@@404
%h3 That page seems to be lost in the clouds!

@@styles
@import url('http://fonts.googleapis.com/css?family=Just+Me+Again+Down+Here|Sniglet:800|Corben:bold|Ubuntu|Chewy&subset=latin');
$bg:#fff;$color: #666;
$primary:#619FEA;
$secondary:#1757A4;
$font:Ubuntu,Times,'Times New Roman',serif;
$titlefont:'Chewy',serif;
$msgfont:'Just Me Again Down Here',sans-serif;
$hfont:'Corben',sans-serif;
$hcolor:$primary;
$hbold:false;

html, body, div, span, object, iframe,h1, h2, h3, h4, h5, h6, p, blockquote, pre,abbr, address, cite, code,del, dfn, em, img, ins, kbd, q, samp,small, strong, sub, sup, var,b, i,dl, dt, dd, ol, ul, li,fieldset, form, label, legend,table, caption, tbody, tfoot, thead, tr, th, td,article, aside, canvas, details, figcaption, figure, footer, header, hgroup, menu, nav, section, summary,time, mark, audio, video{ margin: 0;padding: 0;border: 0;outline: 0;font-size: 100%;vertical-align: baseline;background: transparent; }
article,aside,canvas,details,figcaption,figure,
footer,header,hgroup,menu,nav,section,summary{ display: block; }
body{ font-family: $font;background-color: $bg;color: $color; }
h1,h2,h3,h4,h5,h6{ color:$hcolor;font-family:$hfont;margin:0;@if $hbold { font-weight: bold; } @else {font-weight: normal;}}
h1{font-size:4.2em;}h2{font-size:3em;}h3{font-size:2.4em;}
h4{font-size:1.6em;}h5{font-size:1.2em;}h6{font-size:1em;}
p{font-size:1.2em;line-height:1.5;margin-bottom:0.5em;max-width:40em;}
ul,ol{list-style:none;}
li{font-size:1.2em;line-height:1.5;}
a,a:link,a:visited{color:inherit;}
a:hover{text-decoration:none;}

html{background:$primary;}

@mixin gradient($start: #CCCCCC,$finish: darken($start,25%),$stop: 1){
  -webkit-background-clip: padding-box;
  background: $start;
  background-image: -moz-linear-gradient(top, $start 0%, $finish percentage($stop));
  background-image: -webkit-gradient(linear,left top,left bottom,color-stop(0, $start),color-stop($stop, $finish));
 -pie-background: linear-gradient(top, $start 0%, $finish percentage($stop));
  background-image: linear-gradient(top, $start 0%, $finish percentage($stop));
  behavior: url(PIE.htc);
}

header{padding:5px 0 16px;background:$primary;@include gradient($primary, #fff);
h1{font-size:64px;text-align:center;}}

.content{padding:0 10%;
h1{text-align:center;}
p{margin:0 auto 0.5em;text-align:center;}
.cards{overflow:hidden;
li{float:left;margin-right:10px;
h1{font-size:16px;}}}}

footer{text-align:center;
@include gradient(white,$primary);color:white;font-size:90%;
text-shadow: 0px 1px 0px $primary;
clear:both;margin-top:20px;padding:40px 20px 20px;
.logo{font-size:1.4em;padding-right:0.2em;}}

#card{background:red;
position:relative;height:420px;width:640px;margin:10px auto 0;
h1{font-size:64px;position:absolute;top:0;left:0;width:100%;}
img{max-width:100%;display:block;margin:0 auto;}}

#message{
padding:20px 10px;margin:10px auto;text-align:center;display:block;
background: #fff;border:5px solid #ccc;
font-size: 32px;font-family:$msgfont;  
min-height:4em;_height:4em;width:610px;}

h1.croc{color:#ff6;}
h1.hippo{color:#ff6;}
h1.fish{color:#f6f;}
h1.cake{color:#96f;}
h1.snow{color:#c00;text-shadow: 3px 3px 0 #050;}
h1.robin{color:#c00;text-shadow: 3px 3px 0 #050;}

form{padding-bottom:4em;
label{display:block;margin:10px auto;font-size:60px;font-family:$msgfont;color:#999;}
input{font-size:24px;font-family:verdana,sans-serif;}
input#to{position:relative;left:3.4em;}
input#email{position:relative;left:1.0em;}
input#from{position:relative;left:1.7em;}
#send{background:$primary;color:white;@include gradient($primary,$secondary);
border:1px $secondary solid;border-radius:0.8em;
margin:10px auto;text-align:center;display:block;width:200px;padding:20px 10px;
font-size:48px;text-transform:uppercase;font-weight:bold;
text-shadow:-1px -1px 0px rgba(0,0,0,0.5);}
}

//OOP
.logo,.logo:link,.logo:visited{font-family:sniglet;
color:#fff;text-decoration:none;
text-shadow: 0px 0.15em 0.2em rgba(255,255,255,0.5);}
.logo:hover{text-shadow: 0.1em 0.1em 0.4em rgba(255,255,255,0.7),-0.1em -0.1em 0.4em rgba(255,255,255,0.4);}
.title{font-family:$titlefont;text-align:center;font-weight:bold;}
