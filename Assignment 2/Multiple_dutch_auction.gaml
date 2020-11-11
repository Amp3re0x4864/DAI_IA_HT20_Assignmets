/**
* Name: MultipleDutchAuction
* Author: Noémie and Harshdeep
*/


model MultipleDutchAuction

global {
	
	// Number of participants and auctioneers 
	int PartNo <- rnd(10,20);
	int AuctNo <- rnd(1,10);
	
	// Participant options 
	float speed <- 10.0;
	int part_minPrice <- 10; 
	int part_maxPrice <- 1000;
	
	// Auctioneer options 
	int auct_minPrice <- 100; 
	int auct_maxPrice <- 2000;
	int lowerPrice_min <- 5; 
	int lowerPrice_max <- 100;
	int reservePrice_min <- 100; 
	int reservePrice_max <- 1000; 
	list<string> items <- ['T-shirt','Jean','Dress','CD','Furniture','Painting','Picture','Sculpture']; 
	
	init {
		create Participant number: PartNo {
			location <- {rnd(100),rnd(100)};
			interest <- items[rnd(length(items)-1)]; 
			
		} 
		
		loop i from: 0 to: length(items)-1
		{
			create Auctioneer
			{	
				location <- {rnd(100),rnd(100)};
				product <- items[i];
			}
		}
	}
}

species Participant skills: [moving, fipa] {
	
	// aspect 
	float size <- 0.75;
	rgb color <- #red;
	aspect default {
		draw circle(size) at: location color:color; }
	
	// item interest & price  
	string interest;
	int money <- rnd(part_minPrice,part_maxPrice); 
	
	// auction info 
	Auctioneer target <- nil;
	  
	
	reflex be_crazy when: target=nil {
		do wander; 
	}
	
	reflex receive_accept_proposals when: !empty(accept_proposals) {
        message a <- accept_proposals[0];
        int offer <- int(list(a.contents)[1]);
        write '(Time ' + time + ') --> ' + name + ' wins the auction and pay ' + offer + ' for ' + interest; 
        money <- money - offer; 
		color <- #gold; 
	}
	
	reflex receive_reject_proposals when: !empty(reject_proposals) {
    	message r <- reject_proposals[0];
        write '(Time ' + time + '): ' + name + ' loses the auction ';
    }
	
	// get informed 
	reflex get_informed when: !empty(informs) {
		message inform <- informs[0];
		list content <- inform.contents;
		
		if content[0] = 'Announce' and content[1] = interest {
			target <- inform.sender; 
			target.possibleBuyers <+ self; 
			write '\t' + name + ' is interested in the auction of ' + target.name +  ' with content ' + content[1];
		}
		else if content[0] = 'Auction ended' { 
			target <- nil; 
			write '\t' + name + ' knows the auction of ' + inform.sender + ' is ended';
		}
	} 
	
	// receive proposal and propose 
	reflex receive_cfp_msg when: !empty(cfps) {
        message proposal <- cfps[0];
        write '(Time ' + time + '): ' + name + ' receives a cfp message from ' + agent(proposal.sender).name + ' with content ' + proposal.contents;
		write '\t Willing to pay ' + money;  
		list content <- proposal.contents;
		int offer <- int(content[1]); 
		
		if money >= offer {
			write ' \t Send a proposal of ' + offer + ' to ' + agent(proposal.sender).name;
			do propose with: (message: proposal, contents: ['I want to buy for',offer]);
		}
		else { 
			do refuse with: (message: proposal, contents: ['I do not want to buy for',offer]);
		}
    }

	reflex move_to_target when: target!=nil {
		if location distance_to target.location <= 5 { 
			do wander; 
		}
		else {
			do goto target: target.location speed: speed; 
		}
	}	
}


species Auctioneer skills: [fipa] {
	
	// default aspect 
	int size <- 10;
	rgb color <- #white;
	aspect default 
	{
		draw square(size) at: location color:color; 
	}
	
	// price 
	int price <- rnd(auct_minPrice,auct_maxPrice);
	int reserve_price <- rnd(reservePrice_min,reservePrice_max); 
	
	// product 
	string product;
	
	// info about the auction; 
	list<Participant> possibleBuyers; 
	bool auctionAnnounced <- false; 
	bool auctionStarted <- false;	
	bool auctionDone <- false; 
	
	// Announce auction to all participants using inform protocol 
	reflex announce_auction when: !auctionAnnounced and time >= rnd(10.0,100.0) { 
		write '(Time ' + time + '): ' + name + ' announces the auction to all participants';
		do start_conversation (to :: list(Participant), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['Announce',product]);
		auctionAnnounced <- true; 
		color <- #blue; 
	}
	
	// Start auction when all interested participants are close enough 
	reflex start_auction when: auctionAnnounced and !auctionStarted and !empty(possibleBuyers) and (possibleBuyers max_of (each.location distance_to(location))) <= 10 {
		write '(Time ' + time + '): ' + name + ' starts the auction';
		auctionStarted <- true;
	}
	
	// Receive proposals 
	reflex receive_proposal when: !empty(proposes) {
		bool winner <- false; 
		loop p over: proposes {
			write '(Time ' + time + '): ' + name + ' receives a propose message from ' + agent(p.sender).name + ' with content ' + p.contents ;
            if winner = false {
            	write '\t' + name + ' accepts the proposal of ' + agent(p.sender).name;
            	do accept_proposal with: [message :: p, contents :: ['Win the auction at price ',price]];
            	auctionDone <- true;
            	winner <- true; 
            }
            else { 
            	do reject_proposal with: [message :: p, contents :: ['Lose the auction',price]];
            } 
		}
		do start_conversation with: [to :: possibleBuyers, protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['Auction ended','Selling done']];
		do die;
	}
	
	bool firstRound <- true;
	
	// Send proposal using cfp protocol 
	reflex send_cfp_msg when: auctionStarted and !auctionDone { 
		if firstRound { // don't lower the price for the first cfp 
			firstRound <- false; 
		}
		else {
			price <- price - rnd(lowerPrice_min,lowerPrice_max);
		}
		
		if price < reserve_price {
			write '(Time ' + time + '): ' + name + ' stops the auction because the reserve price is met';
			do start_conversation with: [to :: list(possibleBuyers), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['Auction ended','No selling done']];
			do die; 
		}
		else {
			write '(Time ' + time + '): ' + name + ' sends a cfp message to interested buyers';
			write '\t Sell at price ' + price; 
			do start_conversation with: [ to :: list(possibleBuyers), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Sell at price ',price]];
		}
	}
	
	// 
}

experiment main {
	output{
		display map type: opengl   
		{
			graphics 'layer1' {
                draw Auctioneer;
            }
            graphics 'layer2' {
                draw Participant; 
            }
            species Auctioneer; 
			species Participant;
		}
	}
}