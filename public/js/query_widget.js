    
    /*	
    *     main query widget
    *  
    *     basic idea of UI - user interacts with natural language sentence, not with a web form, 
    *     and get immediate responce after constructing and sending queries
    *     responce is in the form of 2 numbers: for volume and amount of deals returned by her query
    *     if she wants more details she click on these numbers( and we will send additional resource consuming 
    *	  queries to back-end) 
    *     
    *     inspired by Bret Victor and his Tangle.js
    *     cc by @dvrnd, 2012
    */
	var query;  // tis is our main Tangle object, here we collect all info about query
	// var active_color = 'black';
	// var inactive_color = '#bebebe';
	var active_class = 'active';
	var inactive_class = 'inactive';

        // format for millions
        Tangle.formats.millions = function (value) {     // formats 0.42 as "42%"
          return "" + Math.round(value / 10000 )/100;
        };



	// correct ua linguistic for monthes
        function time_name_ua(monthes){
          if( monthes % 100 > 9 && monthes % 100 < 21  ) return 'місяців';
	  switch(monthes % 10){
	    case 1:
 		return "місяць";
	    case 2:
            case 3:
            case 4:
 		return "місяці";
	    default:
 		return "місяців";	
	  }
	}

	// switch on/off part of sentence ('у яких держгроші...')
	function change_dependent_text_status(clas, is_active, is_other_active){
		$(clas).removeClass(active_class).removeClass(inactive_class);
	        if(is_active){
		  // ... trying to switch off
	 	  $(clas).addClass(is_other_active ? active_class : inactive_class );
		} else {
		  // switch on
	 	  $(clas).addClass(active_class);
		}	
        }
 	// switch status for condition and change color
	function flag_und_style(flagVar, element, query){
                    var is_active = query.getValue(flagVar);		
					$(element).removeClass(active_class).removeClass(inactive_class);
                    $(element).addClass(is_active == 1 ? inactive_class : active_class );
                    query.setValue( flagVar, is_active == 1 ? 0 : 1 );
	}
	// produce function for click-logic of simple condition (ie "пов'язані з (галузь)")
	function change_condition_status(element, flagVar, query){
		return function(){
		    var is_active = query.getValue(flagVar);
                    flag_und_style(flagVar, element, query);
		};
	}

	// produce function for click-logic of paired condition (ie "пройшли ... через (установу)")
	function change_composite_status(element, dependent_element, flag, other_flag, query){
                return function(){        
                    var is_other_active = query.getValue(other_flag);
                    var is_active = query.getValue(flag);		
		    change_dependent_text_status(dependent_element, is_active, is_other_active);
                    flag_und_style(flag, element, query);
		};
	}


        /* autocomplete input box half-married to Tangle object */

         // male input box to add ajax autocomplete later
         function create_input(anchor, input_id, value){
		var in_box = new Element('input', 
			{'id': input_id,
			'type': 'text',
			'autocomplete': 'off',
			'value': value }
		).inject($(anchor), 'after'); // find parental div container
               // block click events on input box 
               in_box.addEvent('click', function(e){  e.stopPropagation();  }) 
       }
       // destroy string with old(previous) search result, create input box
       // this function 'flicks', ie it inserts reference on self (by 'flick' var) for next click
       var flick = function( stat_str_id, input_id, anchor, tangle, tangle_var, url){ 
                current = $(stat_str_id); // make elem from id

                create_input(anchor, input_id, current.get('text'));
                
		// choose what to search for? seller or buyer? 
		if(tangle_var == 'dealBuyerId'){
		   var post_param = 'buyer';	
		} else {
		   var post_param = 'seller';	
		}
 
		// create instance of autocompleter based on upper inputbox
		ac = new CwAutocompleter( input_id , url + '/actor',
                  { ajaxMethod: 'post', // use get or post for the request?
		    ajaxParam: post_param, // who to search, seller or buyer?
 		   // targetfieldForKey: 'any_id',   // TODO: make sense of it, maybe with tangle
                    
		    onChoose: function(selection) {
		      //console_log("You selected: " + selection.value + " (" + selection.key + ")");

                      // update tangle  object    magical-mistical connection to tangle (I know it's ugly, bro)
                      tangle.setValue(tangle_var, selection.key);

		      // revert: get search result, make span with string from it (selection.value) 
                      var in_str = new Element('span', 
			    {'id': stat_str_id,
			      'text': selection.value,
			      'class': 'input_complete'
		      });
 
		      // on future click, make input box again	
                      in_str.addEvent('click', function(e){ 
					e.stopPropagation();
					flick(stat_str_id, input_id, anchor, tangle, tangle_var, url); 
		      });
                      in_str.inject($(input_id).getPrevious(), 'after'); // inject after anchor

                      // destroy input box 
                      $(input_id).destroy(); 
                      // kludge to remove hidden list of choices, this magic constant is from cwcompleter.js 
                      $(document.body).getElement('div.cwCompleteOuter').destroy();  	

		   }

                   // temporary stub instead of AJAX requests
		   //doRetrieveValues: function(input) {
		   //   return [['1','example'], ['2','something else']];
		   //}
		});

		// destroy span with string
		current.destroy();
       };

       // eof search input boxes with autocomplete



