# assorted helpers
helpers do
  # rails-style partials. 
  # with one arg: use template name '_arg', set local var to arg, if it's array - repeat for 
  # 	all members
  # with two args, first is template name, second - hash for locals   
  def __partial(template,locals=nil)
    # if first arg string or symbol - then it's a name for template, rename: add underscore
    if template.is_a?(String) || template.is_a?(Symbol)
      template = ('_' + template.to_s).to_sym 
    else # first arg - local vars, so try to find template by underscored class name
      locals = template
      template = template.is_a?(Array) ? ('_' + template.first.class.to_s.downcase).to_sym : 
		('_' + template.class.to_s.downcase).to_sym
    end
    
    # full pack - we got hash with params, and template name, call it all.
    if locals.is_a?(Hash)
      erb(template,{:layout => false},locals)      
    elsif locals
      locals = [locals] unless locals.respond_to?(:inject) # make array
      # if locals is array, iterate all elements with same partial 
      locals.inject([]) do |output,element|
        service_type = element
        output <<  erb(template,{:layout=>false},:locals => {template.to_s.delete("_").to_sym => element})
      end.join("\n")
    else #simple template without variables 
      erb(template,{:layout => false})
    end
  end 

   def partial(template, locals = {})
      erb(template, :layout => false, :locals => locals)
    end

 
  # make links on page as <%= link_to link, 'text'   %>
  def link_to(url,text=url,opts={})
    attributes = ""
    opts.each { |key,value| attributes << key.to_s << "=\"" << value << "\"&"}
    "<a href=\"#{url}\" #{attributes}>#{text}</a>"
  end


end

# correctly cut utf-8 string
class String
  def each_utf8_char
    scan(/./mu) { |c| yield c }
  end

  def cut_me size
    r, i = [], 0
    self.each_utf8_char{|c|  break if i >= size;  r << c; i += 1; }
    r.join('')
  end
  # make each word in string no longer then @limit utf-8 chars (approx 2 * @limit bytes)
  def limit_words limit
    self.split(' ').map{|word| word.length > 2*limit ? word.cut_me(limit)+'...' : word }.join(' ')
  end
  
end



