/**
* Name: Model1
* Based on the internal empty template. 
* Author: Noemie and Harshdeep
* Tags: 
*/


model Model1

/* Insert your model definition here */

global {
	
		
	int GuestNo <- 15;
	int InfoCentreNo <- 1;
	int StoreNo <- 1;
	int hungerRate <-6;
	point InfoCentreLoc <- {50,50};
	init {
		
		create Guest number: GuestNo{
			location <- {rnd(100), rnd(100)};
			}
			
		create Store number: StoreNo
		{
			//location <- {50,50};
		}
		create InfoCentre number: InfoCentreNo
		{
			location <- InfoCentreLoc;
		}
	}
}

species Guest skills: [moving]{
	
	float size<- 0.75;
	rgb color<- #red;
	int max_thirst<- 100; 
	int thirst_rate<-6;
	
	int thirst<- rnd(max_thirst) update: thirst - thirst_rate max: max_thirst; 
	float hunger<- rnd(50)+50.0;
	InfoCentre target<- nil; 
	
	aspect default
	{
		draw sphere(size) at: location color:color; 
	}
	reflex thirsty
	{
		//thirst<- thirst-rnd(hungerRate);
		if (thirst<10){
			color<-#black;
			target<- one_of(InfoCentre);
		}
	}
	reflex beCrazy when: target=nil
	{ 
		do wander;
	}
	reflex move2Target when: target!=nil
	{
		do goto target:target.location;
	}
}

species Store {
	float size<-2.75;
	rgb color<- #blue;
	
	aspect default
	{
		draw square(size) color:color;
	}
}

species InfoCentre {
	float size<-2.75;
	rgb color<- #green;
	
	aspect default
	{
		draw square(size) at: location color:color;
	}
}


experiment main type: gui{
	output{
		display map
		{
			species Guest;
			species Store;
			species InfoCentre;
		}
	}
}
