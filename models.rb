require 'rubygems'
require 'data_mapper'

$service_types = {
  :building =>     ['Будівництво, будівельні матеріали та спецтехніка', 'будівництвом'],
  :goods =>        ['Господарчі товари та культурно-побутова продукція', 'господарчими товарами'],
  :energy =>       ['Енергетика, паливо, хімія', 'енергетикою та хімією'],
  :communal =>     ['Житлово-комунальне, побутове обслуговування та спецтехніка', 'комунальними сервісами'],
  :computers =>    ["Комп'ютери та оргтехніка, програмне забезпечення", 'комп\'ютерами та ІТ'],
  :consult =>      ['Консалтингові послуги, навчання', 'консалтингом'],
  :light =>        ['Легка промисловість', 'легкою промисловістю'],
  :furniture =>    ['Меблі', 'меблями'],
  :medicine =>     ['Медицина та соціальна сфера', 'медициною'],
  :metals =>       ['Метали та продукція металообробки', 'металом'],
  :science =>      ['Наукові дослідження та розробки', 'наукою'],
  :realty =>       ['Нерухомість та оренда', 'нерухомістю'], 
  :print =>        ['Поліграфія, друкарська справа', 'поліграфією'],
  :agriculture =>  ['Сільське господарство', 'сільським господарством'],
  :equipment =>    ['Технологічне обладнання, комплектуючі та матеріали, технічне обслуговування', 'технологічним обладнанням'],
  :services =>     ['Товари, роботи, послуги', 'товарами та послугами'],
  :transport =>    ['Транспортні засоби та комплектуючі, технічне обслуговування, транспортні послуги', 'транспортом'],
  :food =>         ['Харчова промисловість та громадське харчування', 'харчовою промисловістю']
}

$deal_types = {
  :open => 'Відкриті торги',
  :two_stage => 'Двоступеневі торги',
  :one_participant => 'Закупівля в одного учасника',
  :price_request => 'Запит цінових пропозицій', 
  :qualification => 'Попередня кваліфікація учасників',
  :reduction => 'Редукціон', 
  :limited => 'Торги з обмеженою участю'
}

$deal_results = {
  :cancelled_by_lot => 'Відмінені частково (за лотом)',
  :with_winner => 'Завершені з визначенням переможця',
  :partial_result => 'Результат визначений для частини лотів'
}


$currency_course = {
  #########  2008, 2009, 2010, 2011, 2012 
  'GBP' =>  [1000.0, 1100.0, 1250.0, 1260.0, 1265.0],  
  'грн.' => [100.0,  100.0,  100.0,  100.0,  100.0],
  'дол.' => [484.0,  770.0,  800.0,  794.0,  799.0 ],
  'євро' => [715.0,  1100.0, 1020.0, 1140.0, 1050.0 ],
  'руб.' => [19.7, 24.0,  26.0,  27.0,  26.4]
}

#DataMapper::Logger.new(STDOUT, :debug) # this must be called before the setup!
DataMapper.setup(:default, $db)
# set all properties to be required (cannot be nil) by default 
DataMapper::Property.required(true)


# deal with info who paid to whom
class Transaction
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :service_type, Enum[:light, :agriculture, :goods, :furniture, :equipment, :energy, 
				:medicine, :services, :print, :communal, :metals, :transport, 
				:computers, :science, :food, :consult, :realty, :building, :unknown], 
			:default => :unknown
  property :volume, Float, :default => 0 # total amount of money in this transaction,  
  property :deal_date, Date


  # associations
  belongs_to :buyer  # refer to bayer involved in this transaction
  belongs_to :seller # refer to seller 
  belongs_to :procurement_notice # transaction must refer to  notice about procurement 

end

# players - money from, money to
class Seller
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :name, 	String, :length => 255, :index => true, :unique => true
  
  has n, :transactions  # each seller could be involved in many transactions
end

class Buyer
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :name, 	String, :length => 255, :index => true, :unique => true

  has n, :transactions
end


# all additional and meta-info about procurement
class ProcurementNotice
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :subject, String, :length => 512, :index => true, :lazy => true # lazy load detailed description, only on demand
  property :type, Enum[:limited, :open, :two_stage, :one_participant, :price_request, 
			:qualification, :reduction, :unknown], :default => :unknown # type of tender

  property :result, Enum[:cancelled_by_lot, :with_winner, :partial_result, :unknown], :default => :unknown # result
  property :issue, String,  :length => 32, :index => true # number for issue of Visnyk Zakupivel
  property :notice_number, Integer # number from official site "Zakupivli"
  property :pub_date, Date 
  property :url, URI # additional info thru this URL
    
  has n, :transactions # could have some transactions (i.e. one for each winner)

end

# list of subscribers
class Subscriber
  include DataMapper::Resource

  property :id, Serial    # An auto-increment integer key
  property :email, String, :required => true, :format   => :email_address
  property :key_words, String,  :length => 2..32 # key word for search
  property :last_date, Date
  property :confirmed, Boolean, :default  => false

end

# migrate, change schema if we invoke it as script
if __FILE__ == $0
  #DataMapper.auto_migrate! # destroy data, change schema
  DataMapper.auto_upgrade! # change schema without changes in data
end

# final details
DataMapper.finalize # required before any requests to DB -  REALLY BLACK MAGIC HERE, BITCH!!!