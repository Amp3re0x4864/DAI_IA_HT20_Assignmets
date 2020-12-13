/**
* Name: Project Challenge
* Implementation of a BDI architecture  
* Author: Noémie and Harshdeep
*/


model Project

global {
	
	// ADD THE PREDICATES 
	predicate concert_desire <- new_predicate("watch concert desire");
	predicate party_desire <- new_predicate("party desire");
	predicate chill_desire <- new_predicate("chill desire");
	predicate wander_desire <- new_predicate("wander desire");
	
	string concert_at_location <- "concert_at_location";
	string party_at_location <- "party_at_location";
	string chill_at_location <- "chill_at_location";
	
	predicate concert_location <- new_predicate(concert_at_location);
	predicate party_location <- new_predicate(party_at_location);
	predicate chill_location <- new_predicate(chill_at_location);
	
	predicate find_concert_location <- new_predicate("find concert location");
	predicate find_party_location <- new_predicate("find party location"); 
	predicate find_chill_location <- new_predicate("find chill location");  
	
	// Location of the different Events 
	point concertLoc <- {0,50,0};
	point partyPlaceLoc <- {50,0,0}; 
	point chillPlaceLoc <- {100,50,0};
	
	// List of all the guests
	list<string> guest_type <- ['party','chill','shy','happy','sad']; 
	
	// maxDist from location, maxRadius to speak to other people 
	float maxDist <- 7.0;
	float maxRadius <- 10.0; 
	
	// Happiness level 
	map<string,int> happiness_level; 
	
	// Different types of agents 
	init {
		create Concert number:1 { location <- concertLoc; }
		create PartyPlace number: 1 { location <- partyPlaceLoc; } 
		create ChillPlace number: 1 { location <- chillPlaceLoc; }
		create Guest number: 5 { type <- 'happy'; } 
		/*create Guest number: 10 { type <- 'chill'; }
		create Guest number: 10 { type <- 'shy'; }
		create Guest number: 10 { type <- 'happy'; }
		create Guest number: 10 { type <- 'sad'; }*/
		
		loop i from: 0 to: length(guest_type)-1
		{
			add guest_type[i] :: 0 to: happiness_level;
		}
	}
}
 
 species Guest skills: [moving,fipa] control: simple_bdi {
 
 	// Personality Traits 
 	string type; 
	int generous <- rnd(10);
	int outgoing <- rnd(10);
	int drunk <- rnd(10); 

	// Desire   
	string desire <- nil;
	int desire_completion <- 0; 
	
	// target location 
	point target <- nil; 
	
	perceive target: Concert {
        focus id: concert_at_location var: location; 
    }
    
    perceive target: PartyPlace { 
    	focus id: party_at_location var: location;
    }
    
    perceive target: ChillPlace { 
    	focus id: chill_at_location var: location; 
    }
    
    plan concert intention: concert_desire {
    	if (target = nil) {
    		write self.name + " has intention to go towards concert location";
	        do add_subintention(get_current_intention(),find_concert_location, true);
	        do current_intention_on_hold();
	    } 
	    else {
	        do goto target: target ;
	        if (target = location)  {
	        	desire_completion <- desire_completion + 1; 
	        	if desire_completion > 50 { 
	        		write self.name + " has enjoyed a concert"; 
	        		target <- nil; 
	        		desire <- nil; 
	        		desire_completion <- 0; 
	        		do remove_intention(concert_desire,true);
	        	}
	        } 
	    } 
    }
    
    plan find_concert_location intention: find_concert_location { 
    	list<point> possible_concert_locations <- get_beliefs_with_name(concert_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		if empty(possible_concert_locations) { 
			do remove_intention(concert_desire); 
		}
		else { 
			target <- (possible_concert_locations with_min_of (each distance_to self)).location;
		}
		write self.name + " has a belief for a concert location"; 
		do remove_intention(find_concert_location, true);
    }
    
    plan party intention: party_desire { 
    	if (target = nil) {
    		write self.name + " has intention to go towards party location";
	        do add_subintention(get_current_intention(),find_party_location, true);
	        do current_intention_on_hold();
	    } 
	    else {
	        do goto target: target ;
	        if (target = location)  {
	        	desire_completion <- desire_completion + 1; 
	        	if desire_completion > 50 { 
	        		write self.name + " has partied"; 
	        		target <- nil; 
	        		desire <- nil; 
	        		desire_completion <- 0; 
	        		do remove_intention(party_desire,true);
	        	}
	        } 
	    } 
    }
    
    plan find_party_location intention: find_party_location { 
    	list<point> possible_party_locations <- get_beliefs_with_name(party_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		if empty(possible_party_locations) { 
			do remove_intention(party_desire); 
		}
		else { 
			target <- (possible_party_locations with_min_of (each distance_to self)).location;
		}
		write self.name + " has a belief for a party location"; 
		do remove_intention(find_party_location, true);
    }
    
    plan chill intention: chill_desire { 
    	if (target = nil) {
    		write self.name + " has intention to go towards chill location";
	        do add_subintention(get_current_intention(),find_chill_location, true);
	        do current_intention_on_hold();
	    } 
	    else {
	        do goto target: target ;
	        if (target = location)  {
	        	desire_completion <- desire_completion + 1; 
	        	if desire_completion > 50 { 
	        		write self.name + " has enjoyed a chill beer"; 
	        		target <- nil; 
	        		desire <- nil; 
	        		desire_completion <- 0; 
	        		do remove_intention(chill_desire,true);
	        	}
	        } 
	    } 
    }
    
    plan find_chill_location intention: find_chill_location { 
    	list<point> possible_chill_locations <- get_beliefs_with_name(chill_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		if empty(possible_chill_locations) { 
			do remove_intention(chill_desire); 
		}
		else { 
			target <- (possible_chill_locations with_min_of (each distance_to self)).location;
		}
		write self.name + " has a belief for a chill location"; 
		do remove_intention(find_chill_location, true);
    }
    
    plan wander intention: wander_desire {
    	if desire_completion = 0 {
    		write self.name + " has intention to wander"; 
    	}
    	do wander;
    	desire_completion <- desire_completion + 1; 
    	if desire_completion > 50 { 
    		write self.name + " has wandered"; 
    		target <- nil; 
    		desire <- nil; 
    		desire_completion <- 0; 
    		do remove_intention(wander_desire,true);
    	}
    }
    
	reflex chooseDesire when: desire = nil {
		if type = 'party' { 
			switch rnd(99) {
				match_between[0,24] { 
					desire <- 'concert';} 		// 25% concert
				match_between[25,74] { 
					desire <- 'party'; }		// 50% party
													// 0% chill 
				default { desire <- 'wander'; }		// 25% wander 
			}
 		}
 		else if type = 'chill' {
 			switch rnd(99) {
				match_between[0,34] { 
					desire <- 'concert'; } 		// 35% concert
													// 0% party
				match_between[35,89] { 
					desire <- 'chill'; }		// 45% chill 
				default { desire <- 'wander'; }		// 20% wander 
			}
 		}
 		else { // type shy, happy, sad 
 			switch rnd(99) {
				match_between[0,24] { 
					desire <- 'concert'; } 		// 25% concert
				match_between[25,49] {
					desire <- 'party'; }		// 25% party
				match_between[50,74] { 
					desire <- 'chill'; }		// 25% chill 
				default { desire <- 'wander'; }		// 25% wander 
			}
 		}
 		if desire = 'concert' {
 			write self.name + " has a desire of enjoying a concert";
 			do add_desire(concert_desire); 
 		}
 		else if desire = 'party' {
 			write self.name + " has a desire to party"; 
 			do add_desire(party_desire); 
 		}
 		else if desire = 'chill' {
 			write self.name + " has a desire to chill"; 
 			do add_desire(chill_desire); 
 		}
 		else if desire = 'wander' {
 			write self.name + " has a desire to wander"; 
 			do add_desire(wander_desire); 
 		}
		//write self.name + " choose " + desire; 
	}
	
	aspect default {
		if type = 'party' {
			draw sphere(2) at: location color: #blue;	
		}
		else if type = 'chill' {
			draw sphere(2) at: location color: #green;
		}
		else if type = 'shy' {
			draw sphere(2) at: location color: #pink;
		}
		else if type = 'happy' {
			draw sphere(2) at: location color: #red;
		}
		else if type = 'sad' {
			draw sphere(2) at: location color: #grey;
		}
	}
 }

species Event skills: [fipa] {}

species Concert parent: Event { 
	image_file imgEve <- image_file("concert.jpg");
	aspect default { 
		draw imgEve size: {20,15} at: location;
	}	
}

species PartyPlace parent: Event {
	image_file imgEve <- image_file("party.jpg");
	aspect default { 
		draw imgEve size: {20,15} at: location;
	}	
}

species ChillPlace parent: Event { 
	gif_file gif <- gif_file("chill.gif");
	aspect default { 
		draw gif size: {20,15} at: location;
	}	
}

experiment Project type: gui {
	
	output{
		display map type: opengl{
			species Concert;
			species PartyPlace;
			species ChillPlace; 
			species Guest; 
		}	
	}
}