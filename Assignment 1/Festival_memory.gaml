/**
* Name: Festival Scenario 
* Author: Noemie and Harshdeep
* Tags: 
*/


model FestivalMemory

/* Insert your model definition here */

global {
	
	int GuestNo <- 10;
	int InfoCentreNo <- 1;
	int FoodStoreNo <- 2;
	int DrinkStoreNo <- 2; 
	
	int max_hunger <- 500;
	int max_thirst <- 200;
	int hunger_rate <- 5; 
	/* limit at which a Guest can be concidered to be hungry/thirsty */
	int limit <- 15;

	point InfoCentreLoc <- {50,50};
	float InfoCentreSize <- 2.75; 
	float BuildingSize <- 2.0;
	
	init {
		
		create Guest number: GuestNo {
			location <- {rnd(100),rnd(100)};
		}
		create FoodStore number: FoodStoreNo;
		create DrinkStore number: DrinkStoreNo; 
		create InfoCentre number: InfoCentreNo
		{
			location <- InfoCentreLoc;
			FoodStores <- FoodStore at_distance(1000);
			DrinkStores <- DrinkStore at_distance(1000);
		}
	}
}

species Guest skills:[moving]{
	
	float size <- 0.75;
	rgb color <- #red;
	
	int hunger <- rnd(200) update: hunger - rnd(hunger_rate);	
	int thirst <- rnd(100) update: thirst - rnd(hunger_rate); 
	
	list<FoodStore> FoodStores; 
	list<DrinkStore> DrinkStores;
	float gain; 
	
	bool food <- nil; /* food = true when looking for food, false when looking for a drink, nil when wandering */
	Building target <- nil; 
	
	aspect default
	{
		draw circle(size) at: location color:color; 
	}
	
	reflex thirstyOrHungry  when: target=nil and (thirst < limit or hunger < limit)
	{
		string msg <- name; 
		if (thirst < limit and hunger < limit){
			if (thirst <= hunger){ /* Go first drink even if thirst = hunger */
				msg <- msg + ' is thirsty';
				food <- false; 
			}
			else {
				msg <- msg + ' is hungry';
				food <- true;
			}
		}
		else if (thirst < limit) { 
			msg <- msg + ' is thirsty';
			food <- false; 
		}
		else if (hunger < limit){
			msg <- msg + ' is hungry';
			food <- true; 
		}
		
		bool memory; 
		if (length(FoodStores) = FoodStoreNo and length(DrinkStores) = DrinkStoreNo){
			memory <- true; 
			write name + " IS ONLY USING HIS MEMORY";
		}
		else {
			memory <- flip(0.5);
		}
		
		if memory {
			if (!food and !empty(DrinkStores))
			{
				color <- #blue;
				target <- DrinkStores[rnd(length(DrinkStores)-1)];
				msg <- msg + " use memory -> " + target.name; 
				gain <- (location distance_to InfoCentreLoc) + (InfoCentreLoc distance_to target.location) - (location distance_to target.location);
				write "GAIN OF " + gain;
			}
			else if (food and !empty(FoodStores))
			{
				color <- #green;
				target <- FoodStores[rnd(length(FoodStores)-1)];
				msg <- msg + " use memory -> " + target.name; 
				gain <- (location distance_to InfoCentreLoc) + (InfoCentreLoc distance_to target.location) - (location distance_to target.location);
				write "GAIN OF " + gain; 
			}
			else{ /* want to use his memory but has no memory yet */
				color <- #black;
				target <- one_of(InfoCentre);
				msg <- msg + " -> info center";
			}
		}
		else {
			color <- #black;
			target <- one_of(InfoCentre);
			msg <- msg + " -> info center";
		}
		
		write msg; 
	}
	
	reflex beCrazy when: target=nil
	{ 
		do wander;
	}
	
	reflex moveToTarget when: target!=nil
	{
		do goto target: target.location;
	}
	
	reflex askGuest when: target!=nil and target.location = InfoCentreLoc {
		string msg <- name; 
		ask Guest at_distance(5) {
			if (myself.food and !empty(FoodStores)){
				myself.target <- FoodStores[rnd(length(FoodStores)-1)];
				myself.color <- #green;
				msg <- msg + " USE OTHER GUEST MEMORY -> " + myself.target.name;
				write msg;
				gain <- (myself.location distance_to InfoCentreLoc) + (InfoCentreLoc distance_to myself.target.location) - (myself.location distance_to myself.target.location);
				write "GAIN OF " + gain;
			}
			else if (!myself.food and !empty(DrinkStores)){
				myself.target <- DrinkStores[rnd(length(DrinkStores)-1)];
				myself.color <- #blue;
				msg <- msg + " USE OTHER GUEST MEMORY -> " + myself.target.name;
				write msg;
				gain <- (myself.location distance_to InfoCentreLoc) + (InfoCentreLoc distance_to myself.target.location) - (myself.location distance_to myself.target.location);
				write "GAIN OF " + gain;
			}
		}
	}
	
	reflex askInfoCentre when: target!=nil and target.location = InfoCentreLoc and location distance_to(target.location) < InfoCentreSize 
	{
		string msg <- name + ' -> '; 
		ask InfoCentre {
			if !myself.food
			{
				myself.target <- DrinkStores[rnd(length(DrinkStores)-1)];
				myself.color <- #blue;
				msg <- msg + myself.target.name + ' for drink';
			}
			else
			{
				myself.target <- FoodStores[rnd(length(FoodStores)-1)];
				myself.color <- #green;
				msg <- msg + myself.target.name + ' for food';
			}
			write msg; 
		}
	}
	
	reflex drinkOrEat when: target!=nil and target.location != InfoCentreLoc and location distance_to(target.location) < BuildingSize 
	{
		string msg <- name; 
		ask target {
			if myself.food {
				myself.hunger <- max_hunger; 
				msg <- msg + " ate food at " + self.name; 
				if !(myself.FoodStores contains myself.target){
					add item: myself.target to: myself.FoodStores;
				}
			}
			else {
				myself.thirst <- max_thirst; 
				msg <- msg + " drank something at " + self.name;
				if !(myself.DrinkStores contains myself.target){
					add item: myself.target to: myself.DrinkStores;
				}
			}
		}
		write msg; 
		color <- #red;
		target <- nil; 
		food <- nil; 
	}
}

species Building {
	float size <- BuildingSize;
}

species FoodStore parent: Building {
	rgb color <- #green;
	
	aspect default
	{
		draw square(size) color:color;
	}
}

species DrinkStore parent: Building {
	rgb color <- #blue;
	
	aspect default
	{
		draw square(size) color:color;
	}
}

species InfoCentre parent: Building {
	float size <- InfoCentreSize;
	rgb color <- #gold;
	
	list<FoodStore> FoodStores; 
	list<DrinkStore> DrinkStores;
	
	aspect default
	{
		draw square(size) at: location color:color;
	}
}


experiment main {
	output{
		display map
		{
			species Guest;
			species FoodStore;
			species DrinkStore;
			species InfoCentre;
		}
	}
}