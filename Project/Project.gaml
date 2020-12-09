/**
* Name: Project
* Based on the internal empty template. 
* Author: Noemie and Harshdeep
* Tags: 
*/


model Project

/* Insert your model definition here */

global {
	// GLobal Variables 
	bool SantaOnOff <- true;
	bool deerOnOff <- true;
	
	// Different types of agents 
	init{
		create SantaClaus number: 1 {}
		create Reindeer number: 1 {}
		create Eatery number: 1 {}
		create Events number: 3 {}
		create PartyPeople number: 20 {}
		create ChillPeople number: 20 {}
	}
}

species PartyPeople skills: [fipa, moving]{
	// Preferences for other types of people 
	float PartyPref <- rnd(8,10)/10;
	float ChillPref <- rnd(0,5)/10;
	
	// Current Event going on
	float scoreCurrEve<-0.0;
	Events currEve<-nil;
	
	float happiness <- 0.0; // Variable for Happiness Index
	
	// Personality Traits 
	float generous<- rnd(10)/10;
	float openness<- rnd(10)/10;
	bool smokes<-flip(0.5);
	bool previouslyChecked<-false;
	int boughtNow<-0;
	
	// SantaClaus and Reindeer
	SantaClaus SC;
	bool goingtoSC<-false;
	bool SantaMoved<-false;
	
	Reindeer rd;
	bool goingtoDeer<-false;
	
	// Variables for Hunger/Thirst 
	int hunger<- rnd(0,100);
	bool hungry<- false;
	point eateryLoc;
	
	// Personal Space and Wandering 
	point targetpoint <-nil;
	float maxDist<-7.0;
	float maxRadius<-10.0;
	bool ifStopped <-false;
	
	init{
		ask Eatery { myself.eateryLoc <- self.location; }
		ask SantaClaus { myself.SC<-self; }
		ask Reindeer { myself.rd<-self; }
	}
	
	reflex getting_hungry when: hunger > 0{
		if flip(0.8){ hunger<-hunger -1;}
		if hunger=0{
			targetpoint <- eateryLoc;
			hungry<-true;
			goingtoSC<-false;
			goingtoDeer<-false;
			
			scoreCurrEve<-0.0;
			currEve<-nil;
		}
	}
	
	// In Eatery, hunger gets reduced and leaves when full or not appropriate people around
	// Also reflects in buying the food
	reflex eat when: hungry and location distance_to(eateryLoc) <= maxDist{
		hunger <- hunger +10;
		if hunger > 0 and flip(0.8){
			hungry<-false;
			targetpoint<-nil;
			goingtoSC<-false;
			goingtoDeer<-false;
			previouslyChecked<-false;
		}
		
		// Leaves if too many chill people present in the same place
		if length(agents_at_distance(maxRadius) of_species (ChillPeople)) > 10 and !previouslyChecked{
			write self.name + 'too many Chill People eating here! I am leaving!';
			hungry<-false;
			targetpoint<-nil;
			goingtoSC<-false;
			goingtoDeer<-false;
			if hunger < 100{ hunger<-100; }
			previouslyChecked<-false;
			boughtNow<-0;
		}
		
		if boughtNow > 0{ boughtNow<-boughtNow-1; }
	}
	
	// Response to people asking to buy drinks
	reflex replyOffer when: (!empty(cfps)){
		loop i over: cfps{
			message requestFromInitiator <- i;
			string temp <- string(i.contents);
			if flip(generous) and flip(openness) and boughtNow < generous*10{
				boughtNow<-boughtNow+1;
				do propose message: requestFromInitiator contents: ['Yes, Thank you!', true];
			}
			else{
				do propose message: requestFromInitiator contents: ['No, Thanks!', false];
			}
		}
	}
	
	// Read requests from Events when a new event starts
	reflex read_informs when: !(empty(informs)){
		loop i over: informs{
			string temp<- string(i.contents);
			// New Event
			if species(i.sender) = Events{
				float score;
				list<Events> c <- i.contents;
				int xyz <- int(c[1]);
				if xyz=1{ score<- PartyPref;}
				else if xyz=2 { score<- ChillPref; }
				
				if score> scoreCurrEve and !hungry{
					currEve<-i.sender;
					targetpoint<-currEve.location;
					scoreCurrEve<-score;
					goingtoSC<-false;
					goingtoDeer<-false;
				}
			}
			
			// Santa Claus
			else{
				// Santa Claus comes up
				if(length(i.contents)>1){
					float score<-rnd(7,9)/10;
					if score > scoreCurrEve and !hungry{
						currEve<-nil;
						targetpoint<-agent(i.sender).location;
						scoreCurrEve<-score;
						goingtoSC<-true;
						goingtoDeer<-false;
					}
				}
				// People go away from the Santa Claus
				else if flip(0.5) and !hungry{
					targetpoint<-{rnd(100),rnd(100)};
					scoreCurrEve<-0.0;
					goingtoSC<-false;
				}
			}
			
		}
	}
	
	// Reads proposals from Events 
	reflex read_proposes when: !(empty(proposes)){
		loop p over: proposes{
			string temp<- string(p.contents);
			float score;
			list<Events> pc <- p.contents;
			int pcp <- int(pc[1]);
			if pcp = 1{ score<-PartyPref; }
			else if pcp = 2 { score<- ChillPref; }
			
			if score > scoreCurrEve and !hungry{
				currEve<-p.sender;
				targetpoint<-currEve.location;
				scoreCurrEve<-score;
				ifStopped<-false;
				goingtoSC<-false;
				goingtoDeer<-false;
			}
		}
	}
	
	// People may go near Santa Claus
	reflex follow_santa when: goingtoSC and SC.ifmoved and !SantaMoved{
		SantaMoved<-true;
		targetpoint<-SC.location;
	}
	
	// People who do not go near Santa Claus
	reflex donotFollow_santa when: goingtoSC and !SC.ifAppear{
		SantaMoved<-false;
		goingtoSC<-false;
		targetpoint<-nil;
		scoreCurrEve<-0.0;
	}
	
	reflex followDeer when: goingtoDeer and mod(time,20)=0{
		targetpoint<-rd.location;
	}
	
	reflex donotFollow_deer when: goingtoDeer and flip(0.01){
		goingtoDeer<-false;
		targetpoint<-nil;
		scoreCurrEve<-0.0;
	}
	
	// Choosing where to go next
	reflex choosePlace when: targetpoint = nil{
		// A Certain Probability to go to a random place
		if flip(0.05){ targetpoint <- {rnd(100),rnd(100)}; }
		else if SC.ifAppear and SantaOnOff and flip(0.2){
			goingtoSC<-true;
			targetpoint<-SC.location;
			scoreCurrEve<-rnd(7,9)/10;
			currEve<-nil;
		}
		else if deerOnOff and flip(0.2){
			goingtoDeer<-true;
			scoreCurrEve<-rnd(5,7)/10;
			currEve<-nil;
			targetpoint<-rd.location;
		}
		else{
			do start_conversation (to:: list(Events), protocol:: 'fipa-contract-net', performative:: 'cfp', contents:: ['What is the Event: ']);
		}
	}
	
	// Goes to a specified position and stops if closed/Ended
	reflex gotoLoc when: targetpoint !=nil{
		if location distance_to(targetpoint) > maxDist{
			do goto target: targetpoint;
			ifStopped<-false;
		}
		else{
			do wander speed: 0.1;
			ifStopped<-true;
		}
	}
	
	aspect default{
		draw sphere(2) at: location color: #blue;
	}
	
}

species ChillPeople skills: [fipa, moving]{
	
}

species SantaClaus skills: [fipa, moving]{
	
	// Preferences for the type of people in the crowd gathered 
	float PartyPref<- rnd(3,10)/10;
	float ChillPref<- rnd(3,10)/10;
	
	// Charactersitic of SantaClaus; Stress will increase due to situation; Stresslvl for monitoring the data
	float paitence<-rnd(0.80,0.90);
	float stress<-0.0; 
	float stressLvl<-0.0;
	
	// Moving and Environment 
	point targetPoint<- nil;
	bool ifStop <- false;
	float maxDist<-20.0;
	float maxRadius<-12.0;
	
	// When to appear and move around
	bool ifAppear <- false;
	bool ifmoved <- false;
	int timePresent<-0;
	
	init { location<-{-100,-100}; }
	
	reflex timeCalc when: SantaOnOff{
		if flip(0.9){ timePresent<-timePresent+1; }
		if stress>0{ stress <- stress-0.4; }
	}
	
	// Where to appear 
	reflex showUp when: !ifAppear and location < {-50,-50} and timePresent > 400 and flip(0.9) and SantaOnOff{
		timePresent<-0;
		ifAppear<-true;
		write 'Santa Claus has appeared';
		
		loop while: location < {-50,-50}{
			point temp <- {rnd(100),rnd(100)};
			bool clash<-false;
			ask Events{ if temp distance_to(self.location) < myself.maxDist{ clash<-true;} }
			ask Eatery { if temp distance_to(self.location) < myself.maxDist {clash<-true;} }
			if !clash{ location <-temp; }
		}
		
		do start_conversation (to:: list(PartyPeople), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['Santa is coming!!', location]);
		do start_conversation (to:: list(ChillPeople), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['Santa is coming!!', location]);
	}
	
	// Where to move
	reflex wanderAround when: ifAppear and !ifmoved and timePresent > 100 and flip(0.9) and SantaOnOff{
		timePresent<-0;
		loop while: targetPoint = nil{
			point temp <- {rnd(100),rnd(100)};
			bool clash<-false;
			ask Events{ if temp distance_to(self.location) < myself.maxDist{ clash<-true;} }
			ask Eatery { if temp distance_to(self.location) < myself.maxDist {clash<-true;} }
			if !clash{ targetPoint <-temp; }
		}
		
	}
	
	// To disappear after a certain period of time
	reflex goAway when: ifAppear and ifmoved and timePresent > 200 and flip(0.9) and SantaOnOff{
		timePresent<-0;
		ifAppear<-false;
		ifmoved<-false;
		location<-{-100,-100};
		targetPoint<-nil;
		write 'Santa Claus is taking a break; Hence, disappered';
	}
	
	reflex gettingStressed when: SantaOnOff and stress <=0.0{
		stressLvl <- PartyPref * length(agents_at_distance(maxRadius) of_species (PartyPeople)) +
		ChillPref * length(agents_at_distance(maxRadius) of_species (ChillPeople));
		
		if stressLvl > paitence{
			write "Santa Claus is getting uncomfortable; Some people go away!!";
			stress<-maxRadius;
			do start_conversation (to:: list(agents_at_distance(maxRadius)), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['Ease off!']);
		}
	}
	
	// Santa goes to a particular location
	reflex goSomewhere when: targetPoint!=nil and SantaOnOff{
		if location distance_to(targetPoint) > maxDist{
			do goto target: targetPoint;
		}
		else{
			do wander speed: 0.1;
			ifmoved<-true;
		}
	}
	
	aspect default{
		if SantaOnOff{
			draw cylinder(5,3) at: location color: #darkred;
			draw circle(stress) at: location color: #darkgrey;
		}
	}
	
}

species Reindeer skills: [fipa, moving]{
	// Preferences for the type of people in the crowd gathered 
	float PartyPref<- rnd(3,10)/10;
	float ChillPref<- rnd(3,10)/10;
	
	// Charactersitic of SantaClaus; Stress will increase due to situation; Stresslvl for monitoring the data
	float paitence<-rnd(0.80,0.90);
	bool stress<-false; 
	float stressLvl<-0.0;
	bool moveasap<-false;
	
	// Moving and Environment 
	point targetPoint<- nil;
	bool ifStop <- false;
	float maxDist<-20.0;
	float maxRadius<-12.0;
	
	SantaClaus SC;
	
	init {
		location<-{50,50};
		targetPoint<-{50,50};
		ask SantaClaus{ myself.SC<-self; }
	}
	
	reflex stayAway_santa when: ifStop and deerOnOff and location distance_to(SC.location) < maxDist and !moveasap{
		write 'Running Away from Santa Claus';
		moveasap<-true;
	}
	
	reflex gettingStressed when: ifStop and deerOnOff and !moveasap and !stress{
		stressLvl <- PartyPref * length(agents_at_distance(maxRadius) of_species (PartyPeople)) +
		ChillPref * length(agents_at_distance(maxRadius) of_species (ChillPeople));
		
		if stressLvl > paitence{
			write "Too Many people, Deer goes away!!";
			moveasap<-true;
			stress<-true;
		}
	}
	
	reflex choosePlace when: deerOnOff and ifStop and (mod(time,250)=0 or moveasap){
		moveasap<-false;
		
		if float(location.x) <= 50 and float(location.y) <= 50{
			targetPoint<-{rnd(60,90),rnd(10,40)};
		}else if float(location.x) > 50 and float(location.y) <= 50{
			targetPoint<-{rnd(60,90),rnd(60,90)};
		}else if float(location.x) > 50 and float(location.y) > 50{
			targetPoint<-{rnd(10,40),rnd(60,90)};
		}else {
			targetPoint<-{rnd(10,40),rnd(10,40)};
		}
	}
	
	//Goes to a particular locatoin and stops if close
	reflex goToLoc when: targetPoint != nil and deerOnOff{
		if location distance_to(targetPoint) > maxDist{
			do goto target: targetPoint;
			ifStop<-false;
		}else{
			do wander speed: 0.1;
			ifStop<-true;
			stress<-false;
		}
	}
	
	aspect default{
		if deerOnOff{
			if stress{ draw box({8, 4 , 8}) at: location color: #grey; }
			else{ draw box({8, 4 , 8}) at: location color: #darkgrey; }
		}
	}
}

species Events skills: [fipa]{
	// There will be three types of events happening from time to time
	// 0 = Party ; 1 = Carol ; 2 = Show/Movie Screening 
	int type; // The type of the event
	int currEvent; // The current event 
	int eveTime<-0; // Time of the event
	
	// Positioning the events 
	init {
		type <- int(self);
		if type = 0 { location <- {50,0,0}; }
		else if type = 1 { location <- {50,100,0}; }
		else if type = 2 { location <- {100,50,0}; }
		
		currEvent <- type;
	}
	
	reflex newEvent when: eveTime = 0{
		eveTime<-rnd(100,300);
		currEvent <- rnd(0,2);	// select the event type randomly
		
		// Letting the people know that event has been started 
		do start_conversation (to:: list(PartyPeople), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['New Event', currEvent,eveTime]);
		do start_conversation (to:: list(ChillPeople), protocol:: 'fipa-contract-net', performative:: 'inform', contents:: ['New Event', currEvent,eveTime]);
	}	
		// Decreasing the show time because the event has to end for time-being
	reflex decEveTime when: eveTime>0{ eveTime<- eveTime -2; }
	
	// Tell People when they ask which show is going on
	reflex informEvent when: (!empty(cfps)){
		loop i over: cfps{
			message requestFromInitiator <- i;
			string eve<-string(i.contents);
			
			do propose message: requestFromInitiator contents: ['Event going on:', currEvent,eveTime];
		}
	}
	
	aspect default{
		image_file imgEve;
		point eventPosition;
		
		if type=0{ eventPosition<-location+{0,3}; }
		else if type =1{ eventPosition<-location+{5,0}; }
		else { eventPosition<-location+{3,0}; }
		
		if currEvent =0{
			imgEve <- image_file("party.jpg");
			draw imgEve size: {18,13} at: eventPosition;
		}
		else if currEvent =1{
			imgEve <- image_file("carol.jpg");
			draw imgEve size: {20,15} at: eventPosition;
		}
		else{
			imgEve <- image_file("show.jpg");
			draw imgEve size: {20,15} at: eventPosition;
		}
		
	}
}

species Eatery {
	init { location <- {0,50,0}; }
	gif_file eatery <- gif_file("eateryPic.gif");
	aspect default{
		draw eatery size: {20,15} at: location -{2,6}; 
	}
}

experiment Project type: gui {
	parameter "Santa Claus" var: SantaOnOff category: "Agents";
	parameter "Reindeer" var: deerOnOff category: "Agents";
	
	output{
		display map type: opengl{
			species SantaClaus;
			species Reindeer;
			species Eatery;
			species Events;
			species PartyPeople;
			species ChillPeople;
		}
		
		display Charts refresh:every(1#cycles) {
			chart "Hunger Mean" type: series size: {1,0.5} position: {0,0} x_range: 400 y_range: {0,250}{
				data "PartyPeople" value: mean (PartyPeople collect each.hunger) color: #blue;
			}
			
			chart "Stress Levels" type: series size: {1,0.5} position: {0,0.5} x_range: 400 y_range: {0,15}{
				data "Santa Claus" value: SantaClaus collect each.stressLvl color: #red;
				data "Santa Claus Limit" value: SantaClaus collect each.paitence color:#grey;
				data "Reindeer" value: Reindeer collect each.stressLvl color: #brown;
				data "Reindeer limit" value: Reindeer collect each.paitence color: #black;
			}
		}
		
	}
}
