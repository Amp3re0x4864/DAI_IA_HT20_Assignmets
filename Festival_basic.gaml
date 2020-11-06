/**
* Name: Festival Scenario 
* Author: Noemie and Harshdeep
* Tags: 
*/


model Festival

/* Insert your model definition here */

global {
	
	int GuestNo <- 15;
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
		
		create Guest number: GuestNo with: (location: {rnd(100),rnd(100)});
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
	
	Building target <- nil; 
	
	aspect default
	{
		draw circle(size) at: location color:color; 
	}
	
	reflex thirstyOrHungry  when: target=nil and (thirst < limit or hunger < limit)
	{
		string msg <- name; 
		if (thirst < limit and hunger < limit)
		{
			msg <- msg + " is hungry and thirsty";
		}
		else if (thirst < limit){
			msg <- msg + ' is thirsty';
		}
		else if (hunger < limit){
			msg <- msg + ' is hungry';
		}
		
		color <- #black;
		target <- one_of(InfoCentre);
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
	
	reflex askInfoCentre when: target!=nil and target.location = InfoCentreLoc and location distance_to(target.location) < InfoCentreSize 
	{
		ask InfoCentre {
			// First go drink if thirst <= hunger
			string msg <- myself.name + ' is heading to '; 
			if(myself.thirst <= myself.hunger)
			{
				myself.target <- DrinkStores[rnd(length(DrinkStores)-1)];
				myself.color <- #blue;
				msg <- msg + myself.target.name;
				msg <- msg + ' to get a drink';
			}
			else
			{
				myself.target <- FoodStores[rnd(length(FoodStores)-1)];
				myself.color <- #green;
				msg <- msg + myself.target.name;
				msg <- msg + ' to eat something';
			}
			write msg; 
		}
	}
	
	reflex drinkOrEat when: target!=nil and target.location != InfoCentreLoc and location distance_to(target.location) < BuildingSize 
	{
		string msg <- name; 
		ask target {
			if self.type = "Food Store" {
				myself.hunger <- max_hunger; 
				msg <- msg + " ate food at " + self.name; 
			}
			else if self.type = "Drink Store" {
				myself.thirst <- max_thirst; 
				msg <- msg + " drank something at " + self.name;
			}
		}
		write msg; 
		color <- #red;
		target <- nil; 
	}
}

species Building {
	float size <- BuildingSize;
	string type <- "Building";
}

species FoodStore parent: Building {
	rgb color <- #green;
	string type <- "Food Store";
	
	aspect default
	{
		draw square(size) color:color;
	}
}

species DrinkStore parent: Building {
	rgb color <- #blue;
	string type <- "Drink Store";
	
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
