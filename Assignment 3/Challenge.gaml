/**
* Name: Challenge 
* Author: Noémie and Harshdeep
* Description: Concerts in a festival
* 			   use of the utility function to make guests go to there favorite concert 
* 			   global utility regarding the crowd level 
*/


model Challenge

global {
	
	// Number of guests 
	int GuestNo <- 5;
	int StageNo <- 4; 
	float GuestSpeed <- 3.0; 
	
	init {
		create Guest number: GuestNo {
			location <- {rnd(100),rnd(100)};
		}
		create Leader number: 1;
		create Stage number: StageNo {
			location <- {rnd(100),rnd(100)};
		}
	}
}

species Guest skills: [moving, fipa] {
	
	// Aspect 
	float size <- 0.75;
	rgb color <- #red;
	aspect default {
		draw circle(size) at: location color:color; }
	
	Stage target <- nil;
	float maxUtility <- 0.0; 
	
	// Attributes 
	float ligthPref <- rnd(1.0);
	float visualsPref <- rnd(1.0); 
	float speakersPref <- rnd(1.0);
	float bandPref <- rnd(1.0); 
	float rockPref <- rnd(1.0);
	float popPref <- rnd(1.0); 
	float soulPref <- rnd(1.0);  
	float hiphopPref <- rnd(1.0); 
	float crowdPref <- rnd(1.0); 
	list preferences <- [ligthPref,visualsPref,speakersPref,bandPref,rockPref,popPref,soulPref,hiphopPref]; 
	
	// List of utility 
	list<float> utilities;
	int index;
		
	reflex be_crazy when: target = nil {
		do wander; 
	}
	
	reflex move_to_target when: target != nil {
		if location distance_to target.location <= 5 { 
			do wander; }
		else {
			do goto target: target.location speed: GuestSpeed; }
	}	
	
	reflex info_concert when: !empty(informs) { 
		loop info over: informs {
			list contents <- info.contents;
			if (contents[0] = 'Start') {
				do request (message :: info, contents :: ["Attributes values"]);
			}
			else if (contents[0] = 'End' and info.sender = target) {
				do end_conversation (message :: info, contents :: ['Bye']); 
				maxUtility <- 0.0; 
				target <- nil; 
			}
			else if (contents[0] = 'CrowdLevel') { // Recompute utility based on the crowdPref
				list<int> crowdLevel <- contents[1];
				list<float> new_utilities; 
				write name + " recomputes the utility of each stage";
				loop i from: 0 to: length(utilities)-1 {
					int crowdNumber <- crowdLevel[i];
					if index = i {
						crowdNumber <- crowdNumber-1;
					}
					if crowdPref < 0.5 {
						// Guest doesn't like crowd -> add more if less people 
						float added_value <- (1-crowdNumber/GuestNo)*(crowdPref+2);
						new_utilities <+ utilities[i] + added_value;
					}
					else {
						// Guest like crowd -> add more if more people 
						float added_value <- crowdNumber/GuestNo*crowdPref;
						new_utilities <+ utilities[i] + added_value;	
					}
					//write "\tStage" + i + "'s new utility : " + new_utilities[i]; 
				} 
				index <- new_utilities index_of (max(new_utilities));
				if crowdPref < 0.5 {
					write "\tdoesn't like crowd";
				}else {
					write "\tlikes crowd";
				}
				write "\tnew preferred stage : " + index; 
				do inform (message :: info, contents :: [name,max(new_utilities),index]);
						
			}
			else if (contents[0] = 'MaxUtilityReached') {
				list<int> indexes <- contents[1];
				int i <- index_of(Guest, self);
				target <- list(Stage)[indexes[i]];
				write name + " final destination ";
				write "\t --> " + target.name;
				do start_conversation (to :: [target], performative :: 'subscribe', contents :: ["I'm going at your concert"]);
			}
		}
	}
	
	reflex get_attributes when: !empty(proposes) {
		utilities <- [];
		write name + " computes the utility of each stage";
		message toRespond <- nil;
		loop prop over: proposes {
			list<float> attr <- prop.contents;  
			float utility <- 0.0; 
			loop i from: 0 to: length(attr)-1 {
				utility <- utility + attr[i]*preferences[i];
			}
			utilities <+ utility; 
			//write "\t" + agent(prop.sender).name + "'s utility : " + utility; 
		}
		index <- utilities index_of (max(utilities));
		write "\tpreferred stage : " + index; 
		do start_conversation (to :: list(Leader), performative :: 'inform', contents :: [name,max(utilities),index]);
		//write " --> prefers the concert of " + target.name; 
		//do subscribe (message :: toRespond, contents :: ["I'm going at your concert"]);
	}
	
}

species Leader skills:[fipa] { 
	
	float utilities_sum <- 0.0; 
	float new_utilities_sum <- 0.0;  
	list<int> indexes;
	
	reflex global_utility when: !empty(informs) { 
		list infos <- informs; 
		
		write "Leader checks the global utility";
		write '\tlast global utility : ' + utilities_sum;
		
		loop info over: infos { 
			float utility <- float(list(info.contents)[1]);
			new_utilities_sum <- new_utilities_sum + utility; 
		}
		
		if  new_utilities_sum > utilities_sum {
			write '\tnew global utility : ' + new_utilities_sum; 
			utilities_sum <- new_utilities_sum;
			new_utilities_sum <- 0.0;
			indexes <- [];  
			
			list<int> crowdLevel <- [];
			loop i from: 0 to: length(Stage)-1 {
				crowdLevel <+ 0;	
			}
			
			loop info over: infos {
				int index <- int(list(info.contents)[2]);
				crowdLevel[index] <- crowdLevel[index] + 1; 
				indexes <+ index; 
			}
			do start_conversation (to :: list(Guest), performative :: 'inform', contents :: ['CrowdLevel',crowdLevel]);
		}
		else { 
			write "Max utility is reached";
			do start_conversation (to :: list(Guest), performative :: 'inform', contents :: ['MaxUtilityReached',indexes]);
			utilities_sum <- 0.0; 
			new_utilities_sum <- 0.0; 
			indexes <- []; 
		}
			
	}
}

species Stage skills: [fipa] {
	
	// Aspect 
	int size <- 10;
	rgb color <- #blue;
	aspect default {
		draw square(size) at: location color:color; }
	
	// Concert starting time and duration 
	int startConcert <- 10;
	int duration <- 60;
	
	// Attributes 
	float ligth <- rnd(1.0);
	float visuals <- rnd(1.0); 
	float speakers <- rnd(1.0);
	float band <- rnd(1.0); 
	float rock <- rnd(1.0);
	float pop <- rnd(1.0); 
	float soul <- rnd(1.0); 
	float hiphop <- rnd(1.0);
	list attr <- [ligth,visuals,speakers,band,rock,pop,soul,hiphop]; 
	
	reflex start_concert when: time = startConcert { 
		do start_conversation (to :: list(Guest), performative :: 'inform', contents :: ['Start']);
		write name + " starts a concert"; 
	}
	
	reflex send_attributes when: !empty(requests) { 
		loop i over: requests {
			do propose (message :: i, contents :: attr);
		}	
	}
	
	reflex end_concert when: time = startConcert+duration { 
		if !empty(subscribes) {
			loop sub over: subscribes {
				do inform (message :: sub, contents :: ['End']); 
			}
		}
		write name + " ends the concert";
		
		// Start a new concert after 30s 
		startConcert <- startConcert + duration + 30;  
		
		// Change the attributes value
		ligth <- rnd(1.0);
		visuals <- rnd(1.0); 
		speakers <- rnd(1.0);
		band <- rnd(1.0); 
		rock <- rnd(1.0);
		pop <- rnd(1.0); 
		soul <- rnd(1.0); 
		hiphop <- rnd(1.0);
		attr <- [ligth,visuals,speakers,band,rock,pop,soul,hiphop];
	}
	
	
	
}

experiment main {
	output{
		display map type: opengl   
		{
			graphics 'layer1' {
                draw Stage;
            }
            graphics 'layer2' {
                draw Guest;  
            }
            species Stage; 
			species Guest;
			species Leader;
		}
	}
}