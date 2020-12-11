/**
* Name: Project
* Implementation of an entire festival with different types of agents and different places to gather 
* Author: Noémie and Harshdeep
*/


model Project

global {
	
	// Location of the different Events 
	point concertLoc <- {0,50,0};
	point partyPlaceLoc <- {50,0,0}; 
	point chillPlaceLoc <- {100,50,0};
	
	// List of all the guests
	list<string> guest_type <- ['party','chill','shy','happy','sad']; 
	
	// maxDist from location, maxRadius to speak to other people 
	float maxDist <- 7.0;
	float maxRadius <- 10.0;
	
	// Monitoring values 
	int partied <- 0; 
	int enjoyedConcert <- 0; 
	int chilled <- 0; 
	int wandered <- 0;
	int accepted <- 0; 
	int denied <- 0; 
	
	// Happiness level 
	map<string,int> happiness_level; 
	
	// Different types of agents 
	init {
		create Concert number:1 { location <- concertLoc; }
		create PartyPlace number: 1 { location <- partyPlaceLoc; } 
		create ChillPlace number: 1 { location <- chillPlaceLoc; }
		create Guest number: 10 { type <- 'party'; } 
		create Guest number: 10 { type <- 'chill'; }
		create Guest number: 10 { type <- 'shy'; }
		create Guest number: 10 { type <- 'happy'; }
		create Guest number: 10 { type <- 'sad'; }
		
		loop i from: 0 to: length(guest_type)-1
		{
			add guest_type[i] :: 0 to: happiness_level;
		}
	}
}
 
 species Guest skills: [moving,fipa] {
 
 	// Personality Traits 
 	string type; 
	int generous <- rnd(10);
	int outgoing <- rnd(10);
	int drunk <- rnd(10); 
	
	init {  
 		if type = 'party' { 
			outgoing <- rnd(5,10); 
			drunk <- rnd(5,10); 
 		}
 		else if type = 'chill' {
 		}
 		else if type = 'shy' {
 			outgoing <- rnd(4);
 		}
 		else if type = 'happy' {
 			generous <- rnd(7,10);
 			outgoing <- rnd(7,10);
 		}
 		else if type = 'sad' {
 			generous <- rnd(5);
 			outgoing <- rnd(5); 
 		}
 	}
	
	// Desire   
	string desire <- nil;
	int desire_completion <- 0; 
	
	// target location 
	point target <- nil; 
	
	// Stress level for shy person 
	int stress <- 0; 
	bool stressed <- false;
	
	reflex wander when: target = nil and desire = 'wander' {
		if type = 'shy' and stress > 0 { 
			stress <- stress -1;
			if stress = 0 { 
				stressed <- false; 
				write self.name + " of type " + type + " is not stressed anymore";
			}
		}
		desire_completion <- desire_completion + 1; 
		if (desire_completion > 50) {
			wandered <- wandered + 1; 
			desire <- nil; 
			desire_completion <- 0; 
			return; 
		}
		do wander; 
	}
	
	reflex goTotarget when: target != nil {
		if location distance_to target.location <=  maxDist { 
			do wander speed: 1.5; }
		else {
			do goto target: target; }
	}
	
	reflex concert when: desire = 'concert' and location distance_to(target) < maxDist {
		desire_completion <- desire_completion + 1; 
		if (desire_completion > 50) {
			enjoyedConcert <- enjoyedConcert + 1;
			desire <- nil; 
			desire_completion <- 0; 
			return; 
		}
	}
	
	reflex party when: desire = 'party' and location distance_to(target) < maxDist { 
		desire_completion <- desire_completion + 1; 
		if (desire_completion > 50) {
			partied <- partied + 1;
			desire <- nil; 
			desire_completion <- 0; 
			return; 
		}
	}
	
	reflex chill when: desire = 'chill' and location distance_to(target) < maxDist {
		desire_completion <- desire_completion + 1; 
		if (desire_completion > 50) {
			chilled <- chilled + 1; 
			desire <- nil; 
			desire_completion <- 0; 
			return; 
		}
	}
	
	reflex chooseDesire when: desire = nil {
		if type = 'party' { 
			switch rnd(99) {
				match_between[0,24] { 
					desire <- 'concert';
					target <- concertLoc; } 		// 25% concert
				match_between[25,74] { 
					desire <- 'party';
					target <- partyPlaceLoc; }		// 50% party
													// 0% chill 
				default { desire <- 'wander'; }		// 25% wander 
			}
 		}
 		else if type = 'chill' {
 			switch rnd(99) {
				match_between[0,34] { 
					desire <- 'concert';
					target <- concertLoc; } 		// 35% concert
													// 0% party
				match_between[35,89] { 
					desire <- 'chill';
					target <- chillPlaceLoc; }		// 45% chill 
				default { desire <- 'wander'; }		// 20% wander 
			}
 		}
 		else { // type shy, happy, sad 
 			switch rnd(99) {
				match_between[0,24] { 
					desire <- 'concert';
					target <- concertLoc; } 		// 25% concert
				match_between[25,49] {
					desire <- 'party'; 
					target <- partyPlaceLoc; }		// 25% party
				match_between[50,74] { 
					desire <- 'chill';
					target <- chillPlaceLoc; }		// 25% chill 
				default { desire <- 'wander'; }		// 25% wander 
			}
 		}
		//write self.name + " choose " + desire; 
	}
	
	reflex response when: !empty(proposes) {
		message proposal <- proposes[length(proposes)-1];
		
		// get the information of the sender 
		string sender_name <- agent(proposal.sender).name;
		list contents <- proposal.contents;  
		string sender_type <- string(contents[0]); 
		string sender_desire <- string(contents[1]); 
		int sender_generous <- int(contents[2]); 
		int sender_outgoing <- int(contents[3]);
		int sender_drunk <- int(contents[4]);
		
		
		// If happy person around him : makes him more happy irrespective of the continuation of the conversation 
		if sender_type = 'happy' { 
			happiness_level[type] <- happiness_level[type] + sender_outgoing + sender_generous + sender_drunk; 
		}
		// If sad person around him : makes him less happy irrespective of the continuation of the conversation 
		else if sender_type = 'sad' {
			happiness_level[type] <- happiness_level[type] - sender_outgoing - sender_generous - sender_drunk;
		}
		
		/****** PARTY PERSON  ******/
		if type = 'party' {
			// If at concert : enjoy concert only with people more drunk or more outgoing 
			if location distance_to concertLoc < maxDist { 
				if sender_outgoing >= outgoing or sender_drunk >= drunk {
					write name +  " with type " + type + " is enjoying a concert with " + sender_name + " with type " + sender_type; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					
					if sender_type = type { 
						happiness_level[type] <- happiness_level[type] + 10; 
						happiness_level[sender_type] <- happiness_level[sender_type] + 10;
					}
					else { 
						happiness_level[type] <- happiness_level[type] + 5;
						happiness_level[sender_type] <- happiness_level[sender_type] + 5;
					}
				} 
				else { 
					write name +  " with type " + type + " is not enjoying a concert with " + sender_name + " with type " + sender_type + " less outgoing and drunk then him"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					
					if sender_type = type { 
						happiness_level[type] <- happiness_level[type] - 10;
						happiness_level[sender_type] <- happiness_level[sender_type] - 10; 
					}
					else { 
						happiness_level[type] <- happiness_level[type] - 5; 
						happiness_level[sender_type] <- happiness_level[sender_type] - 5;
					}
				}
			} 
			
			// If at party place : party only with party and happy people irrespective of their traits  
			if location distance_to partyPlaceLoc < maxDist {
				if sender_type = 'party' or sender_type = 'happy' {
					write name +  " with type " + type + " is partying with " + sender_name + " with type " + sender_type; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					
					if sender_type = type { 
						happiness_level[type] <- happiness_level[type] + 10; 
						happiness_level[sender_type] <- happiness_level[sender_type] + 10;
					}
					else { 
						happiness_level[type] <- happiness_level[type] + 5;
						happiness_level[sender_type] <- happiness_level[sender_type] + 5; 
					}
				} 
				else { 
					write name +  " with type " + type + " is not partying with " + sender_name + " with type " + sender_type + " because of different type"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					happiness_level[type] <- happiness_level[type] - 5; 
					happiness_level[sender_type] <- happiness_level[sender_type] - 5;
				}
			}
			
			// If at chill place  
			if location distance_to chillPlaceLoc < maxDist{ 
				// DO NOTHING -> Party people don't go chill 
			}
		}
		
		/****** CHILL PERSON  ******/
		else if type = 'chill' {
			// If at concert : enjoy concert only with people less drunk or less outgoing 
			if location distance_to concertLoc < maxDist { 
				if sender_outgoing <= outgoing or sender_drunk <= drunk {
					write name +  " with type " + type + " is enjoying a concert with " + sender_name + " with type " + sender_type; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					
					if sender_type = type { 
						happiness_level[type] <- happiness_level[type] + 10; 
						happiness_level[sender_type] <- happiness_level[sender_type] + 10;
					}
					else { 
						happiness_level[type] <- happiness_level[type] + 5; 
						happiness_level[sender_type] <- happiness_level[sender_type] + 5;
					}
				} 
				else { 
					write name +  " with type " + type + " is not enjoying a concert with " + sender_name + " with type " + sender_type + "more outgoing and more drunk then him"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					
					if sender_type = type { 
						happiness_level[type] <- happiness_level[type] - 10; 
						happiness_level[sender_type] <- happiness_level[sender_type] - 10;
					}
					else { 
						happiness_level[type] <- happiness_level[type] - 5; 
						happiness_level[sender_type] <- happiness_level[sender_type] - 5;
					}
				}
			} 
			
			// If at party place 
			if location distance_to partyPlaceLoc < maxDist {
				// DO NOTHING -> Chill people don't party
			}
			
			// If at chill place  
			if location distance_to chillPlaceLoc < maxDist{ 
				if sender_generous >= 5 or outgoing >= 5 {
					write name +  " with type " + type + " is accepting a beer from " + sender_name + " with type " + sender_type + " generous enough"; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					
					if sender_type = type { 
						happiness_level[type] <- happiness_level[type] + 10; 
						happiness_level[sender_type] <- happiness_level[sender_type] + 10;
					}
					else { 
						happiness_level[type] <- happiness_level[type] + 5; 
						happiness_level[sender_type] <- happiness_level[sender_type] + 5;
					}
				} 
				else { 
					write name +  " with type " + type + " is refusing a beer from " + sender_name + " with type " + sender_type + " not generous enough"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					
					if sender_type = type { 
						happiness_level[type] <- happiness_level[type] - 10; 
						happiness_level[sender_type] <- happiness_level[sender_type] - 10;
					}
					else { 
						happiness_level[type] <- happiness_level[type] - 5; 
						happiness_level[sender_type] <- happiness_level[sender_type] - 5;
					}
				}
			}	
		}
			
		/****** HAPPY PERSON  ******/
		// Don't care about the happiness of a happy person (always happy) : just make people more happy around him 
		else if type = 'happy' {
			// If at concert : enjoy concert with almost everybody 
			if location distance_to concertLoc < maxDist { 
				if sender_outgoing >= 2 or sender_generous >= 2 {
					write name +  " with type " + type + " is enjoying a concert with " + sender_name + " with type " + sender_type + " outgoing enough or generous enough"; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1;
					 
					happiness_level[sender_type] <- happiness_level[sender_type] + 10;
				} 
				else { 
					write name +  " with type " + type + " is not enjoying a concert with " + sender_name + " with type " + sender_type + "not outgoing and generous enough"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					happiness_level[sender_type] <- happiness_level[sender_type] - 2; 
				}
			} 
			
			// If at party place : party with everyone 
			if location distance_to partyPlaceLoc < maxDist {
				write name +  " with type " + type + " is partying with " + sender_name + " with type " + sender_type; 
				do accept_proposal message: proposal contents: ["Let's go!!!"];
				accepted <- accepted + 1; 
				happiness_level[sender_type] <- happiness_level[sender_type] + 10;
			}
			
			// If at chill place : accept beers from almost everybody
			if location distance_to chillPlaceLoc < maxDist { 
				if sender_generous >= 2 and outgoing >= 2 {
					write name +  " with type " + type + " is accepting a beer from " + sender_name + " with type " + sender_type + " generous enough"; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					happiness_level[sender_type] <- happiness_level[sender_type] + 10;
				} 
				else { 
					write name +  " with type " + type + " is refusing a beer from " + sender_name + " with type " + sender_type + " not generous enough"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					happiness_level[sender_type] <- happiness_level[sender_type] - 2;
				}
			}
		}
		
		/****** SAD PERSON  ******/
		// Don't care about the happiness of sad person (always sad) : just make people more sad around him 
		else if type = 'sad' {
			// If at concert : accept if less outgoing or less generous 
			if location distance_to concertLoc < maxDist { 
				if sender_outgoing <= outgoing or sender_generous <= generous {
					write name +  " with type " + type + " is enjoying a concert with " + sender_name + " with type " + sender_type + " less outgoing or less generous"; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					happiness_level[type] <- happiness_level[type] + 2; 
				} 
				else { 
					write name +  " with type " + type + " is not enjoying a concert with " + sender_name + " with type " + sender_type + " too outgoing and generous"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					happiness_level[sender_type] <- happiness_level[sender_type] - 10;
				}
			} 
			
			// If at party place : don't party with anyone
			if location distance_to partyPlaceLoc < maxDist {
				write name +  " with type " + type + " is not partying with " + sender_name + " with type " + sender_type; 
				
				denied <- denied + 1; 
				happiness_level[sender_type] <- happiness_level[sender_type] - 10;
			}
			
			// If at chill place  
			if location distance_to chillPlaceLoc < maxDist { 
				if sender_generous >= 3 and outgoing >= 3 {
					write name +  " with type " + type + " is accepting a beer from " + sender_name + " with type " + sender_type + " generous enough"; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					happiness_level[sender_type] <- happiness_level[sender_type] + 2;
				} 
				else { 
					write name +  " with type " + type + " is refusing a beer from " + sender_name + " with type " + sender_type + " not generous enough"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					happiness_level[sender_type] <- happiness_level[sender_type] - 10;
				}
			}
		}
		
		
		/****** SHY PERSON  ******/
		else if type = 'shy' {
			// If at concert : accepts if not too shy 
			if location distance_to concertLoc < maxDist { 
				if outgoing >= 3 {
					write name +  " with type " + type + " is enjoying a concert with " + sender_name + " with type " + sender_type; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					
					happiness_level[type] <- happiness_level[type] + 10;
					happiness_level[sender_type] <- happiness_level[sender_type] + 5; 
				} 
				else { 
					write name +  " with type " + type + " is not enjoying a concert with " + sender_name + " with type " + sender_type; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					
					happiness_level[type] <- happiness_level[type] - 5; 
					happiness_level[sender_type] <- happiness_level[sender_type] - 5;
				}
			} 
			
			// If at party place : party if drunk enough  
			if location distance_to partyPlaceLoc < maxDist {
				if drunk >= 5 { 
					write name +  " with type " + type + " is partying with " + sender_name + " with type " + sender_type; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					
					happiness_level[type] <- happiness_level[type] + 10; 
					happiness_level[sender_type] <- happiness_level[sender_type] + 5;	
				}
				else {
					write name +  " with type " + type + " is not partying with " + sender_name + " with type " + sender_type; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					
					happiness_level[type] <- happiness_level[type] - 5; 
					happiness_level[sender_type] <- happiness_level[sender_type] - 5;
				}
			}
			
			// If at chill place : accept if sender not too drunk and generous enough  
			if location distance_to chillPlaceLoc < maxDist { 
				if sender_generous >= 3 and sender_drunk <= 3 {
					write name +  " with type " + type + " is accepting a beer from " + sender_name + " with type " + sender_type + " generous enough and not too drunk"; 
					do accept_proposal message: proposal contents: ["Let's go!!!"];
					accepted <- accepted + 1; 
					
					happiness_level[type] <- happiness_level[type] + 10; 
					happiness_level[sender_type] <- happiness_level[sender_type] + 5;
				} 
				else { 
					write name +  " with type " + type + " is refusing a beer from " + sender_name + " with type " + sender_type + " not generous enough or too drunk"; 
					do reject_proposal message: proposal contents: ["No thanks"];
					denied <- denied + 1; 
					
					happiness_level[type] <- happiness_level[type] - 5; 
					happiness_level[sender_type] <- happiness_level[sender_type] - 5;
				}
			}
		}
		
		
		
	}
	
	Guest previously_asked <- nil; 
	
	// Start a conversation with someone at the same event  
	reflex start_conversation when: !empty(Guest at_distance maxRadius) and desire!='wander' and location distance_to(target) < maxDist {
		list<Guest> neighbors <- Guest at_distance maxRadius; 
		Guest selected_neighbor <- neighbors[rnd(length(neighbors)-1)]; 
		if (outgoing > 5 or drunk > 7 or flip(0.3)) and type != 'shy' and selected_neighbor != previously_asked {
			do start_conversation (to:: [selected_neighbor], protocol:: 'fipa-contract-net', performative:: 'propose', contents:: [type,desire,generous,outgoing,drunk]);
			previously_asked <- selected_neighbor; 
		}
	}
	
	// If there is too many people around, the shy person will be stressed and will go away 
	reflex people_around when : !empty(Guest at_distance maxRadius) and type = 'shy' and desire!='wander' {
		list<Guest>  guest_list <- Guest at_distance maxRadius; 
		stress <- length(guest_list);
		if stress > outgoing { 
			target <- nil; 
			desire <- 'wander';
			stressed <- true; 
			write self.name + " of type " + type + " is too stressed and goes away";  
		}
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
		
		
		display Chart refresh:every(1#cycles) {
			/* 
			chart "Number of desires completed" type: series size: {1,0.5} position: {0,0} x_range: 400 y_range: {0,250} {
				data "Party" value: partied color: #blue; 
				data "Chill" value: chilled color: #green; 
				data "Enjoy concert" value: enjoyedConcert color: #red;
				data "Wander" value: wandered color: #yellow;
			}*/
			
			chart "Happiness Level" type: series size: {1,1} position: {0,0} x_range: 300 y_range: {0,1000} {
				data "Party people" value: happiness_level['party']/10 color: #blue; 
				data "Chill people" value: happiness_level['chill']/10 color: #green; 
				data "Shy people" value: happiness_level['shy']/10 color: #pink; 
			}
		}
		
		display Pie refresh:every(1#cycles) {
			chart "Stress ratio of shy people" type: pie style: exploded size: {1, 0.5} position: {0, 0} {
		        data "Stressed" value: Guest count (each.type='shy' and each.stressed) color: #magenta ;
		        data "Non-stressed" value: Guest count (each.type='shy' and !each.stressed) color: #blue ;
	    	}
		}
		
	}
}


