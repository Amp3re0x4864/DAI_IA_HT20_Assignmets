/**
* Name: Model1
* Author: Noemie and Harshdeep
* Tags: 
*/


model Model1

/* Insert your model definition here */

global {
	
		
	int GuestNo <- 15;
	int InfoCentreNo <- 1;
	int FoodStoreNo <- 1;
	int WaterStoreNo <- 1; 

	point InfoCentreLoc <- {50,50};
	
	init {
		
		create Guest number: GuestNo 
		{
			location <- {rnd(100),rnd(100)};
		}	
		create FoodStore number: FoodStoreNo;
		create WaterStore number: WaterStoreNo; 
		create InfoCentre number: InfoCentreNo
		{
			location <- InfoCentreLoc;
		}
	}
}

species Guest skills:[moving]{
	
	float size <- 0.75;
	rgb color <- #red;
	int max_hunger <- 100;
	int hunger_rate <- 5; 
	
	int hunger <- rnd(max_hunger) update: hunger - rnd(hunger_rate) max: max_hunger;	
	int thirst <- rnd(max_hunger) update: thirst - rnd(hunger_rate) max: max_hunger; 
	
	InfoCentre target <- nil; 
	
	aspect default
	{
		draw circle(size) at: location color:color; 
	}
	
	reflex thirsty  
	{
		if (thirst<10){
			color <- #black;
			target <- one_of(InfoCentre);
		}
		if (hunger<10){
			color <- #black;
			target <- one_of(InfoCentre); 
		}
	}
	
	reflex beCrazy when: target=nil
	{ 
		do wander;
	}
	
	reflex moveToTarget when: target!=nil
	{
		do goto target:target.location;
	}
}

species FoodStore {
	float size<-2.75;
	rgb color<- #green;
	
	aspect default
	{
		draw square(size) color:color;
	}
}

species WaterStore {
	float size<-2.75;
	rgb color<- #blue;
	
	aspect default
	{
		draw square(size) color:color;
	}
}

species InfoCentre {
	float size<-2.75;
	rgb color<- #gold;
	
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
			species FoodStore;
			species WaterStore;
			species InfoCentre;
		}
	}
}
