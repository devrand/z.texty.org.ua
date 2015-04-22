#
# Z - public procurements in Ukraine, (cc) dvrnd for texty.org.ua, 2012 
#

require 'rubygems'
require 'json' 
require 'sinatra'
require 'data_mapper'
require 'pony'
require 'nokogiri'
require 'open-uri'

load 'settings.rb'
load "models.rb"
load "lib/helpers.rb"

def construct_query query_conditions, params

  if params[:market] 
    s_t = params[:market].to_i 
    s_t_symbol = Transaction.service_type.options[:flags][s_t] 
    query_conditions[:service_type] = s_t_symbol
  end
 
  if params[:buyer]
    buyer_id = params[:buyer].to_i
    query_conditions[:buyer_id] = buyer_id
  end

  if params[:seller]
    seller_id = params[:seller].to_i
    query_conditions[:seller_id] = seller_id
  end

  if params[:sum]
    treshould = params[:sum].to_i * 1000000
    query_conditions[:volume.gt] = treshould # search for bigger then treshould
  end
  # eof constructing query
    query_conditions
end

def interval m
  m = m.to_i
  n = (m-1) * 30 + Time.now.day  # days
end

def search params, limit
  #make query
  if limit > 0
    query_conditions = {:limit => limit}
  else
    query_conditions = {}
  end

  if params[:date_from] =~ /^\d\d\/\d\d\/\d\d\d\d$/ && params[:date_to] =~ /^\d\d\/\d\d\/\d\d\d\d$/
    query_conditions[:deal_date.gt] = Date.strptime( params[:date_from],  '%d/%m/%Y')
    query_conditions[:deal_date.lt] = Date.strptime( params[:date_to],  '%d/%m/%Y')
  end
  if params[:service_type] && params[:service_type] != "all" && $service_types.include?(params[:service_type].to_sym)
    query_conditions[:service_type] = params[:service_type]
  end
  if params[:volume_from] && params[:volume_to] && params[:volume_to].to_i > params[:volume_from].to_i
     query_conditions[:volume.gt] = params[:volume_from]
     query_conditions[:volume.lt] = params[:volume_to]
  end
  if params[:key_word] && params[:key_word].split.empty? == false
    key_word = "%#{params[:key_word].split}%"
    query_conditions1 = query_conditions.merge({Transaction.seller.name.like => key_word })
    query_conditions2 = query_conditions.merge({Transaction.buyer.name.like => key_word })
    query_conditions3 = query_conditions.merge({Transaction.procurement_notice.subject.like => key_word })
    tenders = Transaction.all(query_conditions1) + Transaction.all(query_conditions2) + Transaction.all(query_conditions3)
  else
    tenders = Transaction.all(query_conditions)
  end
  if params[:sort] && params[:order]
    sort_param = DataMapper::Query::Operator.new(params[:sort], params[:order])
  else
    sort_param = :deal_date.desc
  end
  tenders.all(:order => [sort_param])
end

def get_news(n = 3)
  rss = Nokogiri::XML(open("http://texty.org.ua/mod/news/?view=rss"))
  news = rss.xpath('//xmlns:item').map do |i|
    {:title => i.xpath('xmlns:title').text, :url => i.xpath('xmlns:link').text}
  end
  news.first(n)
end
################# routes for main pages ######################
configure do
  # set cache timelife for static files
  # set :static_cache_control, [:public, {:max_age => 300}]
end

# main page going ...
get '/' do
  @title = 'Головна сторінка: пошук по базі даних тендерів, 2008-2014 рік'
  @url = $api_url
  @page_js = partial :"_main_js"

  # make array with short description of all service types (see models.rb)
  @service_types = Transaction.service_type.options[:flags].map do |flag|
    next if flag == :unknown
    $service_types[flag][1]
  end
  @news = get_news
  erb :container_main 
end

#page for entity
get '/buyer/:id' do
  halt 500 unless id = params[:id].to_i
  b = Buyer.get(id)  
  name = b.name
  role = 'buyer'  
  p_role = 'seller'
   
  @url = $api_url

  # obj vars - for templates
  @title = "Замовник: #{name} - Пошук по базі даних тендерів, 2008-2012 рік"
  @header1 = 'кому платила ця установа?'
  @header2 = 'за що платила?'
  # find data for charts
  
  @page_js = partial(:"_firm_js", { :url => @url, :chart_title2 => "ЩОРІЧНІ ОБ'ЄМИ", 
                                        :chart_title3 => "НАЙБІЛЬШІ ОТРИМУВАЧІ КОШТІВ",
					:role => role, :id => id})

  result = []
  # get total for all deals
  sum, count = Transaction.all(:buyer_id => id).aggregate(:volume.sum, :all.count)
  # , but limit number of returned deals to 100
  # TODO: add possibility to download all deals in zipped, csv - format 
  deals = Transaction.all(:buyer_id => id, :limit => 100, :order => [:deal_date.desc])
  #sum, count = deals.aggregate(:volume.sum, :all.count)
  
  deals.each do |deal|
    pn = deal.procurement_notice
    result << { :seller => {:name => deal.seller.name.limit_words(32), :id=> deal.seller_id }, 
		# cut long words, after some treshold
		:subject => pn.subject.limit_words(64), 
                :id => deal.id, 
		:date => deal.deal_date, 
		# volume - in thousands 
		:volume => "%.1f" % (deal.volume / 1000) } 
  end
  
 
  erb :container_firm, :locals => {:name => name.limit_words(22), 
					# total in millions
					:volume => "%.2f" % (sum / 1000000), 
					:dnum => count , 
					:deals => result,
					:role => p_role  } 
end

# TODO: DRY for get /buyer and get /seller
#page for entity
get '/seller/:id' do
  halt 500 unless id = params[:id].to_i
  b = Seller.get(id)  
  name = b.name
  role = 'seller'  
  p_role = 'buyer'
 
  @url = $api_url

  # obj vars - for templates
  @title = "Отримувач коштів: #{name} - Пошук по базі даних тендерів, 2008-2012 рік"
  @header1 = 'Хто заплатив цій установі?'
  @header2 = 'за що отримала кошти?'

  # find data for charts
  
  @page_js = partial(:"_firm_js", { :url => @url, :chart_title2 => "ЩОРІЧНІ ОБ'ЄМИ", 
                                        :chart_title3 => "НАЙБІЛЬШІ ПЛАТНИКИ",
					:role => role, :id => id})

  result = []
  # get total for all deals
  sum, count = Transaction.all(:seller_id => id).aggregate(:volume.sum, :all.count)
  # , but limit number of returned deals to 100
  # TODO: add possibility to download all deals in zipped, csv - format 
  deals = Transaction.all(:seller_id => id, :limit => 100, :order => [:deal_date.desc])
  
  deals.each do |deal|
    pn = deal.procurement_notice
    result << { :seller => {:name => deal.buyer.name.limit_words(32), :id=> deal.buyer_id }, 
		# cut long words, after some treshold
		:subject => pn.subject.limit_words(64),
                :id => deal.id, 
		:date => deal.deal_date, 
		:volume => "%.1f" % (deal.volume / 1000) } 
  end
  
 
  erb :container_firm, :locals => {:name => name.limit_words(22), 
					:volume => "%.2f" % (sum / 1000000), 
					:dnum => count , 
					:deals => result,
					:role => p_role  } 
end

get '/deal/:id' do
  halt 500 unless id = params[:id].to_i
  @url = $api_url
  @tenders_url = 'https://tender.me.gov.ua'

  deal = Transaction.get(id)
  proc_notice = deal.procurement_notice
  buyer = { :name => deal.buyer.name,   :id => deal.buyer.id }
  seller = { :name => deal.seller.name, :id => deal.seller.id }
 
 
  dresult = $deal_results[proc_notice.result]
  dtype = $deal_types[proc_notice.type]
  dmarket = $service_types[deal.service_type][0]   

  @title = proc_notice.subject

  erb :container_deal, :locals => { :buyer => buyer, :seller => seller, 
				    :volume => "%.1f" % (deal.volume / 1000), 
				    :deal_date => deal.deal_date, 
				    :deal_result => dresult,
                                    :deal_type => dtype, 
				    :deal_subj => proc_notice.subject,#.limit_words(64),
				    :deal_market => dmarket, :deal_issue => proc_notice.issue,
				    :deal_url => @tenders_url + proc_notice.url  }

end

# web form for search
get '/search' do
  @title = 'Пошук по базі даних тендерів, 2008-2012 рік'
  tenders = search(params, 0)
  sum, count = tenders.aggregate(:volume.sum, :all.count)
  result = tenders.all( :limit => 100 )
  sum ||= 0 
  @page_js = partial(:"_search_js", { 
          :url => $api_url, 
          :posts_start => 100, 
          :tenders_per_request => 100,
          :number_of_tenders => count,
          :params => params})
  erb :container_search, :locals => { 
          :tenders => result,
          :volume => "%.2f" % (sum / 1000000), 
          :dnum => count ,
          :service_types => $service_types,
          :date_from => params[:date_from] || Time.local(2008, 1, 1).strftime('%d/%m/%Y'),
          :date_to => params[:date_to] || Time.now.strftime('%d/%m/%Y'),
          :volume_from => params[:volume_from],
          :volume_to => params[:volume_to],
          :key_word => params[:key_word],
          :service_type => params[:service_type] || "all",
          :sort => params[:sort] || "deal_date",
          :order => params[:order] || "desc"
        }
end

get "/search.csv" do
  tenders = search(params, 1000)
  headers "Content-Disposition" => "attachment;filename=search_result_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv",
    "Content-Type" => "application/octet-stream"
  result = CSV.generate do |csv|
    csv << ['Замовник', 'Виконавець', 'Предмет', 'Дата', 'Сума'] 
    tenders.each do |tender|
      csv << [tender.buyer.name, tender.seller.name, tender.procurement_notice.subject, tender.deal_date, tender.volume]
    end
  end
end

# form for subscribe
get "/subscribe" do
  @title = 'XYZ - Підписка на оновлення за ключевим словом по базі даних тендерів'
  @subscribers = Subscriber.all
  erb :container_subscriber
end

post "/subscribe" do
  @title = 'XYZ - Підписка на оновлення за ключевим словом по базі даних тендерів'
  subscriber = Subscriber.new(:email => params[:email], :key_words => params[:key_words], :last_date => Transaction.first(:order => [:deal_date.desc]).deal_date)
  if subscriber.save
    @message = "Ваша заявку на підписку прийнята. В найближчий час Вам прийде повідомлення на email з підтвердженням."
    Pony.mail(:to => subscriber.email , :from => 'no-reply@ztexty.org.ua', :subject => 'hi', :body => 'Hello there.')
  else   
    @errors = subscriber.errors.full_messages
  end
  erb :container_subscriber
end

# page with top-100 sellers and top-100 buyers
get "/statistics" do
  @title = 'XYZ - Топ-100 замовників та виконавців'
  @page_js = partial :"_statistics_js"
  @top_buyers = repository(:default).adapter.select("SELECT buyers.id, buyers.name, sum(transactions.volume) AS total_volume FROM transactions INNER JOIN buyers ON transactions.buyer_id = buyers.id GROUP BY buyers.id ORDER BY total_volume DESC LIMIT 100" )
  @max_buyer_value = (@top_buyers.first)[:total_volume]
  @top_sellers = repository(:default).adapter.select("SELECT sellers.id, sellers.name, sum(transactions.volume) AS total_volume FROM transactions INNER JOIN sellers ON transactions.seller_id = sellers.id GROUP BY sellers.id ORDER BY total_volume DESC LIMIT 100" ) 
  @max_seller_value = (@top_sellers.first)[:total_volume]
  erb :container_statistics
end


get "/test_send_mail" do
  Pony.mail(:to => "0979029562@mail.ru" , :from => 'no-reply@ztexty.org.ua', :subject => 'hi', :body => 'Hello there.')
  erb "Send mail"
end
# #########################  API start
# TODO: rewrite mess with query conditions below in 'post '/''

# main query
post '/query' do

  #n = params[:monthes].to_i * 30 # days
  #m = params[:monthes].to_i
  #n = (m-1) * 30 + Time.now.day  # days

  n = interval params[:monthes]
  
  # start constructing query
  query_conditions = {  :deal_date.gt => Date.today - n, 
			:deal_date.lt => Date.today }
  query_conditions = construct_query(query_conditions, params) 
  sum, count = Transaction.all( query_conditions ).aggregate(:volume.sum, 
							:all.count)
  #send JSON with total volume and number of deals for query  
  {:volume => sum, :number => count }.to_json  
end


# send data to fill top table on first page
post '/table' do

  limit = 50
  #n = params[:monthes].to_i * 30 # days
  n = interval params[:monthes]
  # start constructing query
  query_conditions = {  :deal_date.gt => Date.today - n, 
			:deal_date.lt => Date.today, 
			:order => [:volume.desc], :offset => params[:start].to_i, :limit => limit }
  query_conditions = construct_query(query_conditions, params) 
  ts = Transaction.all( query_conditions )
  result = []
  ts.each do |deal|
    buyer = deal.buyer.name
    seller = deal.seller.name 
    result << [[buyer, deal.buyer_id], [seller, deal.seller_id ], 
			[deal.deal_date, nil], [deal.volume, deal.id]]
  end

  #send JSON with table result
  result.to_json  
end

# route for interactive autocomplete form 
post '/actor' do
  if params[:buyer]
    clas = Buyer 
    name = params[:buyer]
  elsif params[:seller]
    clas = Seller
    name = params[:seller]
  else
    return [].to_json # cant find meaningful var in post request
  end

  if  name and name.length < 512 and name.length > 5
    bs = clas.all(:name.like => "%#{name}%", :limit => 100)
    # limit_words: cuts a names in result which is above some length	
    bs.map{|b|  [b.id, b.name.limit_words(22)]}.to_json
  end

end


# produce data for little charts on firm's page
# to optimise, i broke it down to raw SQL

post '/chart' do
  player =  params[:player].gsub(/[']/, '')
  id = params[:id].to_i
  rez = []
  if params[:type].to_s == 'time'
    # find volumes for each years from 2008 to 2011
    volumes = repository(:default).adapter.select("SELECT SUM(`volume`), 
	YEAR(`deal_date`) as y FROM `transactions` 
	WHERE `#{player}_id` = #{id}  GROUP BY y")   
    # make last year automatic
    2008.step(Time.new.year, 1) do |year|
      if e = volumes.detect{|e| e['y'] == year}
        rez << [year, e['sum(`volume`)']]
      else
        rez << [year, 0]
      end
    end 
  elsif params[:type].to_s == 'diagramm' 
    # find 5 most successfull partners
    other_role = player == "buyer" ? "seller" : "buyer"
    table_name = other_role + 's'
    r = repository(:default).adapter.select("SELECT #{table_name}.name, sum(transactions.volume) AS total_volume, #{table_name}.id FROM transactions  INNER JOIN #{table_name} ON transactions.#{other_role}_id = #{table_name}.id and transactions.#{player}_id = ? GROUP BY #{table_name}.id ORDER BY total_volume DESC LIMIT 5", id ) 
   rez = r.map{|e| [e['name'], e['total_volume'], e['id']] }  
  end
  rez.to_json
end

# return result of the search
post '/search' do
  tenders = search(params, 0)
  result = tenders.all( :offset => params[:start].to_i, :limit => 100 )
  erb :"_search_result", :layout => false,  :locals => { :tenders => result }
end
# #############  API end #######################
