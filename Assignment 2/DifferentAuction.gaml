model DifferentAuction



global {
	Guests guest;
	list<Guests> refuser_list;
	list<Guests> proposer_list;
	list auctionType <- ["Dutch","English","Sealed"];
	int price <- rnd(150,200);
	
	init {
		
//		create Auctioneers_dutch number: 1;
		
//		create Auctioneers_english number:1;
		create Auctioneers_sealed number:1;
		create Guests number: 5;

	}
}

species Auctioneers_dutch skills: [fipa]{
	
	int min_price <-150;
//	int max_acceptable_price;
	int status <-1; //1 - no one buy it. 0-sold out.
	
	aspect default {
		draw rectangle(4, 4) color:#red;	
	}
	
	reflex startAuction when: (time = 2) {
//		Guests g <- Guests at 0;
		write 'Start Auction: ' + name + ' sends cfp msg to all guests participating in auction ';
		do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Sell for price: ' + price] ];
		
	}
	
	reflex startAuction_inform when: (time = 1) {
//		Guests g <- Guests at 0;
		write 'Start inform: ' + name + ' sends inform of auction ';
		
		do start_conversation with: [to :: list(Guests), protocol :: 'no-protocol', performative :: 'inform', contents :: ['Selling a shirt','Dutch'] ];
	}
	
	reflex receiveProposal when: !empty(proposes){
//		write '(Time ' + time + '): ' + name + ' receives propose messages';
		
		loop p over: proposes {
			
			list content <- list(p.contents);
			int p2 <- 10;

			do comparePrice(p, p2);
			
		}
		
		if status =1{
			if price = min_price {
				do informAuctionEnd;
				return;
			}else{
				price <- price - 10;
				if price < min_price{
					price <- min_price;
				}
				write '(Time ' + time + '): ' + name + ' start a new cfp at price '+price;
				do start_conversation with: [to :: proposer_list, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Sell for price: ' + price] ];
			}
				
		}else if status =0{
			do informAuctionEnd;

		}
	}
	
	
	action informAuctionEnd{
		do start_conversation with: [to :: list(proposer_list), protocol :: 'no-protocol', performative :: 'inform', contents :: ['end of auction'] ];
	
	}
	
	
	
	
	action comparePrice(message p,int price2){
		
		
		if(price2>=price and status =1){
			write '(Time ' + time + '): ' + name + ' accept propose from '+ agent(p.sender).name +'at price '+price;
			do accept_proposal with: [ message :: p, contents :: ['sell it at price'] ];
			status <-0;
		}else{
			write '(Time ' + time + '): ' + name + ' REJECT propose from '+ agent(p.sender).name +'at price '+price;
			do reject_proposal with: [ message :: p, contents :: ['reject'] ];
		}
	}
	
	
	

	
}


species Auctioneers_english skills:[fipa]{
	int min_price <- 150;
	Guests winner <- nil;
	int startTime <- nil;
	aspect default {
		draw rectangle(4, 4) color:#red;	
	}
	
	reflex startAuction_inform when: (time = 1){
		write 'auctioneer sends out auction information';
		do start_conversation with: [to :: list(Guests), protocol :: 'no-protocol', performative :: 'inform', contents :: ['Selling a house','English'] ];
	}
	
	reflex startAuction when:(time = 2){
		write 'start auction';
		do start_conversation with: [to :: proposer_list, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Sell for price: ' + price] ];
//		waitForProposes <-true;
	}
	
	reflex recvProposal when:!empty(proposes){
		
		loop p over: proposes {
			
			list content <- p.contents;
			int p2 <- int(content[1]);
			
			if p2>price{
				price <- p2;
				winner <- Guests(agent(p.sender));
			}
			
		}
//		waitForProposes <- false;
		do broadcastPrice(price);
		
	}
	reflex noProposal when: empty(proposes) and startTime != nil and (time = startTime + 5){
		write 'no proposal time: '+ time;
		if(winner != nil){
			do start_conversation with: [to :: list(winner), protocol :: 'fipa-contract-net', performative :: 'accept_proposal', contents :: [price] ];
		}
		do start_conversation with: [to :: proposer_list, protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['END'] ];
	}
	
	action broadcastPrice(int newpirce){
		do start_conversation with: [to :: proposer_list, protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Sell for price: ' + price] ];
//		waitForProposes <- true;
		write 'startTime: '+time;
		startTime <- time;
	}
	
}


species Auctioneers_sealed skills: [fipa]{
	string type <- 'clothes';
	list<Guests> guests;
	int price <- rnd(20, 150);
	int min_price <-60;
//	int max_acceptable_price;
	int status <-1; //1 - no one buy it. 0-sold out.
	int maxPrice <- 0;
	//message winner <- nil;
	Guests winner <- nil;
	
	aspect default {
		draw rectangle(4, 4) color: (type = "clothes")? #red : #blue;	
	}
	
	reflex startAuction_inform when: (time = 1) {
		write 'Informing auction: ' + name + ' starting of type: ' + type;
		
		do start_conversation with: [to :: list(Guests), protocol :: 'no-protocol', performative :: 'inform', contents :: ['Selling: '+ type,'Sealed'] ];
	}
	
	reflex startAuction when: (time = 2) {
		write 'Starting auction: ' + name + ' starting of type: ' + type + ' (sends cfp msg to all guests)';
		do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Selling: ' + type + ' Please place your bid'] ];	
		
	}
	
	reflex receiveProposal when: !empty(proposes){
		
		loop p over: proposes {
			list content <- p.contents;
			int p2 <- int(content[0]);
			write name + ' got an offer from ' + p.sender + ' of ';
			if(p2 > maxPrice) {
				maxPrice <- p2;
				winner <- Guests(agent(p.sender));
//				write ''+winner.name;
			}
		}
		
		do start_conversation (to: list(winner), protocol: 'fipa-contract-net', performative: 'accept_proposal', contents: ['win']);
		write name + ' bid ended. Sold to ' + winner.name;
		//do accept_proposal with: (message: winner2, contents: ['Congrats you won!']);
//		write ''+length(guests);
		do start_conversation (to: proposer_list, protocol: 'fipa-contract-net', performative: 'inform', contents: ["end bid"]);
		proposer_list <- [];
	}
}






species Guests skills: [moving, fipa]{
	
	int status <-0; //0- end auction, 1- in auction.
	int my_price <-0 ;
	int auction_type <-0;
	Auctioneers_english targete <- nil;
	Auctioneers_dutch targetd <- nil;
	Auctioneers_sealed targets <- nil;
	aspect default {
		draw circle(2) color:#green;		
	}
	
	reflex be_crazy when: targete=nil {
		do wander; 
	}
	
	reflex recvAccept when: !(empty(accept_proposals)) and status=1{
		message msg <-accept_proposals[0];
		write '(Time ' + time + '): '+ name + ' buy from '+ agent(msg.sender).name +' at price '+ price;
//		status<-0;
	}
	
	
	reflex recvReject when: !(empty(reject_proposals)) and status =1{
		message msg <-reject_proposals[0];
		write '(Time ' + time + '): '+name +' get reject from '+ agent(msg.sender).name+ ' ';
//		status<-0;
	}
	
	reflex receiveCFP when: !(empty(cfps)) and auction_type=0 {
		message proposalFromInitiator <- cfps[0];
		

		if(self in proposer_list){
			if price < my_price{
				my_price <- price;
			}else{
				if my_price =0{
					my_price <- price - rnd(100);
				}
				
			}
			write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ' with content ' + proposalFromInitiator.contents;
			write '(Time ' + time + '): ' + name + ' propose to ' + agent(proposalFromInitiator.sender).name + ' with price ' + price +' and bid for '+ my_price;
			do propose with: [ message :: proposalFromInitiator, contents :: [my_price] ];
		}else if(self in refuser_list){
			do refuse with: [ message :: proposalFromInitiator, contents :: ['not understood'] ];
		}
		
	}
	
	
	reflex receiveCFP_english when: !(empty(cfps)) and auction_type=1 {
		message proposalFromInitiator <- cfps[0];
		

		if(self in proposer_list){
			write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ' with content ' + proposalFromInitiator.contents;
			
			if(flip(0.5)){
				my_price <- price + rnd(50) ;
				write '(Time ' + time + '): ' + name + ' propose to ' + agent(proposalFromInitiator.sender).name + ' with price ' + price +' and bid for '+ my_price;
				do propose with: [ message :: proposalFromInitiator, contents :: [my_price] ];
			}else{
				
			}
			
		}else if(self in refuser_list){
//			do refuse with: [ message :: proposalFromInitiator, contents :: ['not understood'] ];
		}
		
	}
	
	reflex receiveCFP_sealed when: !(empty(cfps)) and auction_type=2{
		message proposalFromInitiator <- cfps[0];
		
		
		Auctioneers_sealed auctionInitiator <- Auctioneers_sealed(proposalFromInitiator.sender);
		
		
		if (self in proposer_list){
			
			auctionInitiator.guests <+ self;
			status <- 1;
			my_price <- rnd(200) ;
			//write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + auction.name + ' with content ' + proposalFromInitiator.contents;
			write '(Time ' + time + '): ' + name+' is interested in ' +' proposal from '+ auctionInitiator.name + ' and bid for '+ my_price;
			do start_conversation (to: proposalFromInitiator.sender, protocol: 'fipa-propose', performative: 'propose', contents: [my_price]);
//			auction <- nil;
		} else {
//			write 'log:'+ name+' is not interested in proposal';
			do refuse with: [ message :: proposalFromInitiator, contents :: ['not understood'] ];
		}
		
		
	}
	
	
	
	reflex recvInformStart when: !(empty(informs)) and status = 0{
		message msg <- informs[0];
		
		
		if(flip(0.7)){
			int xyz <- rnd(0,2);
			write '(Time ' + time + '): ' + name+' is interested in proposal from '+ agent(informs[0].sender).name+' '; 
			add self to: proposer_list;
			if(xyz = 0){
				auction_type <-1;
			}else if(xyz = 1){
				auction_type <-0;
			}else if(xyz = 2){
				auction_type <-2;
			}
			status<-1;
		}else{
			write '(Time ' + time + '): ' + name+' is NOT interested in proposal from '+ agent(informs[0].sender).name+' '; 
			add self to: refuser_list;
		}
//		write "length: "+ length(queries);
		do end_conversation with:[ message :: msg, contents :: ['we know'] ];
	}
	
	reflex recvInformEnd when: !(empty(informs)) and status = 1{
		message msg <- informs[0];
		Auctioneers_sealed informingAuction <- Auctioneers_sealed(agent(msg.sender));
		write '(Time ' + time + '): ' + name + ' receive from '+ agent(msg.sender).name +'about ';
		if(auction_type=2){
			remove self from: informingAuction.guests;
		}
		status<-0;
		auction_type <-0;
		my_price <-0;
		do end_conversation with:[ message :: msg, contents :: ['end auction'] ];
		
	}
}

experiment fipa type:gui {
	output {
		display map {
			species Auctioneers_dutch;
			species Auctioneers_english;
			species Auctioneers_sealed;
			species Guests;
		}
	}
}
