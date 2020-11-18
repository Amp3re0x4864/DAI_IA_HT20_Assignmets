/**
* Name: Task2 
* Author: Noémie and Harshdeep
* Description: Concerts in a festival
* 			   use of the utility function to make guests go to there favorite act 
*/


model Task2

global {
	
	// Number of guests 
	int GuestNo <- 5;
	int StageNo <- 4; 
	float GuestSpeed <- 5.0; 
	
	init {
		create Guest number: GuestNo {
			location <- {rnd(100),rnd(100)};
		}
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
	list preferences <- [ligthPref,visualsPref,speakersPref,bandPref,rockPref,popPref,soulPref,hiphopPref,crowdPref]; 
		
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
			else if (contents[0] = 'End') {
				do end_conversation (message :: info, contents :: ['Bye']); 
				maxUtility <- 0.0; 
				target <- nil; 
			}
		}
	}
	
	reflex get_attributes when: !empty(proposes) {
		write name + " computes the utility of each stage";
		message toRespond <- nil;
		loop prop over: proposes {
			list<float> attr <- prop.contents;  
			float utility <- 0.0; 
			loop i from: 0 to: length(attr)-1 {
				utility <- utility + attr[i]*preferences[i];
			}
			write "\t" + agent(prop.sender).name + "'s utility : " + utility; 
			if maxUtility < utility {
				maxUtility <- utility; 
				target <- prop.sender; 
				toRespond <- prop;
			}
		}
		write "--> prefers the concert of " + target.name; 
		do subscribe (message :: toRespond, contents :: ["I'm going at your concert"]);
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
	float crowd <- rnd(1.0); 
	list attr <- [ligth,visuals,speakers,band,rock,pop,soul,hiphop,crowd]; 
	
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
		crowd <- rnd(1.0); 
		attr <- [ligth,visuals,speakers,band,rock,pop,soul,hiphop,crowd];
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
		}
	}
}
