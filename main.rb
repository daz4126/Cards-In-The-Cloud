########### Libraries ###########
%w[rubygems sinatra dm-core dm-migrations haml sass pony digest/md5].each{ |lib| require lib }

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
  greetings = %w[Hi Hello Hola Hallo Ciao Sawubona Merhaba Labdien Ola Szervusz Howdy]
  @greeting = greetings[rand(greetings.size)]
  haml :index
end

get '/new/card/:id' do
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
    %meta(charset="utf-8")
    %title= @title || settings.name
    %link(rel="stylesheet" media="screen, projection" href="/styles.css")
    /[if lt IE 9]
      %script(src="http://html5shiv.googlecode.com/svn/trunk/html5.js")
  %body
    %header(role="banner")
      %h1 <a title="home" href="/">#{ settings.name }</a>
    .content
      = yield
  
@@index
%h1= @greeting + "!"
%p Welcome to #{settings.name}. The easiest way to send an electronic greetings card to your friends and family.
%p Choose a card from the list below then click on the picture to send it!
%ul.cards
  %li
    %h3 Let It Snow!
    %a(href="/new/card/1")
      %img(src="/snowman-th.png")
  %li
    %h3 Rocking Robins
    %a(href="/new/card/2")
      %img(src="/robins-th.png")
%footer(role="contentinfo")
  %small <a href="/">#{settings.name}</a> is and always will be a free service. Why not make a donation to charity to say thank you?
  .charities
    %a(href="http://www.unicef.org.uk/Donate/Donate-Now/" alt="Donate to Unicef")
      %img(src="unicef-logo.png")
    %a(href="http://www.amnesty.org.uk/content.asp?CategoryID=2064" alt="Donate to Amnesty International")
      %img(src="ai_logo.gif")
    %a(href="https://www.oxfam.org.uk/donate/" alt="Donate to Oxfam")
      %img(src="logo_oxfam.gif")

@@new
#card
  =haml @design
%form(action="/send" method="post")
  %label(for="to")To:<input type="text" name="to" id="to">
  %label(for="email")Email:<input type="text" name="email" id="email">
  %textarea#message(name="card[message]")Write your message here...
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
%footer(role="contentinfo")
  %small This card was brought to you by <a href="/">#{settings.name}</a>. Why not make a donation to charity to say thank you?
  .charities
    %a(href="http://www.unicef.org.uk/Donate/Donate-Now/" alt="Donate to Unicef")
      %img(src="unicef-logo.png")
    %a(href="http://www.amnesty.org.uk/content.asp?CategoryID=2064" alt="Donate to Amnesty International")
      %img(src="ai_logo.gif")
    %a(href="https://www.oxfam.org.uk/donate/" alt="Donate to Oxfam")
      %img(src="logo_oxfam.gif")
      
@@design1
%h1= "Let It Snow! Let It Snow!"
%img(src="/snowman.png")

@@design2
%h1= "Rocking Robins!"
%img(src="/robins.png")

@@design3
%h1= "Hippo Birthday!"
%img(src="/hippo.png")
 
@@404
%h3 Sorry, but that page cannot be found

@@styles
@import url("http://fonts.googleapis.com/css?family=Just+Me+Again+Down+Here|Sniglet:800|Corben:bold|Ubuntu|Chewy&subset=latin");
$bg: #fff;$color: #666;
$primary: #619FEA;$secondary:#1757A4;
$font: Ubuntu,Times,"Times New Roman",serif;
$hcolor: $primary;$hfont: 'Corben',sans-serif;
$hbold: false;
$acolor:$primary;$ahover:$secondary;$avisited:lighten($acolor,10%);

html, body, div, span, object, iframe,h1, h2, h3, h4, h5, h6, p, blockquote, pre,abbr, address, cite, code,del, dfn, em, img, ins, kbd, q, samp,small, strong, sub, sup, var,b, i,dl, dt, dd, ol, ul, li,fieldset, form, label, legend,table, caption, tbody, tfoot, thead, tr, th, td,article, aside, canvas, details, figcaption, figure, footer, header, hgroup, menu, nav, section, summary,time, mark, audio, video{ margin: 0;padding: 0;border: 0;outline: 0;font-size: 100%;vertical-align: baseline;background: transparent; }
article,aside,canvas,details,figcaption,figure,
footer,header,hgroup,menu,nav,section,summary{ display: block; }
body{ font-family: $font;background-color: $bg;color: $color; }
h1,h2,h3,h4,h5,h6{ color:$hcolor;font-family:$hfont;margin:0;@if $hbold { font-weight: bold; } @else {font-weight: normal;}}
h1{font-size:4.2em;}h2{font-size:3em;}h3{font-size:2.4em;}
h4{font-size:1.6em;}h5{font-size:1.2em;}h6{font-size:1em;}
p{font-size:1.2em;line-height:1.5;margin:0.5em 0;max-width:40em;}
ul,ol{list-style:none;}
li{font-size:1.2em;line-height:1.5;}
a,a:link{color:$acolor;}
a:visited{color:$avisited;}
a:hover{color:$ahover;text-decoration:none;}

.content{padding:0 20px;}

header{background:$primary;border-bottom:5px solid $secondary;
a,a:link,a:visited{color:#fff;text-decoration:none;}
h1{
font-family:sniglet;
font-size:48px;
text-align:center;
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

.cards{margin-bottom:200px;}


footer{clear:both;margin-top:40px;}

#card{
position:relative;height:420px;width:640px;margin:10px auto 0;
h1{
  font-size: 64px;
  font-family:'Chewy',serif;
  color:#43A966;
  text-shadow: 3px 3px 0 #050;
  text-align:center;
  font-weight:bold;
}
img{max-width:100%;display:block;margin: 0 auto;position:absolute;top:0;left:0;z-index:-1;}
}

form{float:left;margin-left:50px;position:relative;padding-bottom:4em;
label{display:block;margin:10px auto;font-size:60px;font-family:'Reenie Beanie', serif;;color:#999;}
input{font-size:24px;font-family:verdana,sans-serif;}
input#to{position:relative;left:3.4em;}
input#email{position:relative;left:1.0em;}
input#from{position:relative;left:1.7em;}
}
#send{font-size:48px;background:#f04137;color:#fff;border:none;border-radius:12px;position:absolute;bottom:0;right:0;}
