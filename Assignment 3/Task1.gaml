/**
* Name: NewModel
* Based on the internal empty template. 
* Author: Noemie and Harshdeep
* Tags: 
*/


model NewModel

/* Insert your model defiyition here */

global {
	int nearbyQueen <- 8;
	int nQueen <- 12;
	
	init {
		create royalEvent number: nQueen;
	}
	
	list<battleground> tltCells;
	list<royalEvent> tltQueens;
	
	bool looking <- false;
}

species royalEvent {
	battleground oneCell <- one_of(battleground);
	list<list<int>> GridMap;
	
	init {	//Allocate Free Cell
		loop dot over: oneCell.neighbours{
			if dot.queen = nil{
				oneCell <- dot;
				break;
			}
		}
		location <- oneCell.location;
		oneCell.queen <- self;
		add self to: tltQueens;
		do updateGridMap;
		
	}
	
	action updateGridMap{
		self.GridMap <- [];
		loop i from: 0 to: nQueen-1{
			list<int> tempList;
			loop j from: 0 to: nQueen-1{
				add 0 to: tempList;
			}
			add tempList to: GridMap;
		}
	}
	
	action placeGridMap{
		do updateGridMap;
		
		// Identification of all occupied cell
		loop dot over: tltCells{
			if dot.queen != nil and dot.queen !=self{
				self.GridMap[dot.grid_x] [dot.grid_y] <- 1000;
			}
		}
		
		// Identifying all the free cells
		loop dot over: tltCells{
			int x <- dot.grid_x;
			int y <- dot.grid_y;
			if self.GridMap[int(x)][int(y)] = 1000{
				loop i from: 1 to: nQueen{
					// Up
					int xi <- int(x) +i;
					if xi < nQueen{
                            self.GridMap[xi][y] <- self.GridMap[xi][y] + 1;
                        }
                   
                    //Down
                    int y_xi <- int(x) - i;
                    if y_xi > -1{ self.GridMap[y_xi][y] <- self.GridMap[y_xi][y] + 1;}
                        
                    // Right
                    int yi <- int(y) + i;
                    if yi < nQueen{ self.GridMap[x][yi] <- self.GridMap[x][yi] + 1; }
                        
                    //Left
                    int y_yi <- int(y) - i;
                    if y_yi > -1{ self.GridMap[x][y_yi] <- self.GridMap[x][y_yi] + 1; }
                        
                    //top right diagonal
                    if xi < nQueen and yi < nQueen{ self.GridMap[xi][yi] <- self.GridMap[xi][yi] + 1;  }
                        
                    //bottom right diagonal
                    if y_xi > -1 and yi < nQueen{ self.GridMap[y_xi][yi] <- self.GridMap[y_xi][yi] + 1;  }
                        
                    //top left diagonal
                    if xi < nQueen and y_yi > -1{ self.GridMap[xi][y_yi] <- self.GridMap[xi][y_yi] + 1; }
                        
                    //bottom left diagonal
                    if y_xi > -1 and y_yi > -1{ self.GridMap[y_xi][y_yi] <- self.GridMap[y_xi][y_yi] + 1; }
				}
			}
		}
	}
	list<point> freeCells(int val) {
        list<point> Checks ;
        loop dot over: tltCells{
            int x <- dot.grid_x;
            int y <- dot.grid_y;
            if self.GridMap[int(x)][int(y)] = val and !(x = oneCell.grid_x and y = oneCell.grid_y){
            	add {int(x),int(y)} to: Checks;
            }
        }
        return Checks;
    }
    
    royalEvent LocateQueenLoc(int xy){
    	list<royalEvent> caughtQueens;
    	
    	loop dot over: tltCells{
            int x <- dot.grid_x;
            int y <- dot.grid_y;
            
            if self.GridMap[x][y] > 999{
            	if x = self.oneCell.grid_x {
            		add dot.queen to: caughtQueens;
            	}
            	else if y = self.oneCell.grid_y {
            		add dot.queen to: caughtQueens;
            	}
            	else{
            		int diff_x <- abs(x - self.oneCell.grid_x);
            		int diff_y <- abs(y - self.oneCell.grid_y);
            		if diff_x = diff_y{
            			add dot.queen to: caughtQueens;
            		}
            	}
            }
        }
    	
    	if length(caughtQueens) > 0{
    		royalEvent sight <- caughtQueens[rnd(0, length(caughtQueens)-1)];
    		return sight;	
    	} else{
    		return nil;
    	}
    }
    action needToMove{
    	do placeGridMap();
	    if self.GridMap[oneCell.grid_x][oneCell.grid_y] != 0{
	    	list<point> possibleChecks <- freeCells(0);
	    	if length(possibleChecks) > 0 {
	    		point possiblePoint <- possibleChecks[rnd(0,length(possibleChecks)-1)];
	    		loop c over: tltCells {
	    			if c.grid_x = possiblePoint.x and c.grid_y = possiblePoint.y and c.queen = nil{
	    				oneCell.queen <- nil;
	    				oneCell <- c;
	    				location <- c.location;
	    				oneCell.queen <- self;
	    				
	    				write name;
	    				write "Options: " + possibleChecks;
	    				write "Moved to: " + c.grid_x + ", " + c.grid_y;
	    				write "Grid: " + self.GridMap;
	    				break;
	    			}
	    		}
	    	}
	    	else{
	    		write "I cannot move from: " + self.oneCell.grid_x + ", " + self.oneCell.grid_y;
	    		// Communicate with others for moving
	    		royalEvent sight <- LocateQueenLoc(0);
	    		if sight != nil{
	    			battleground sightCell;
	    			ask sight{
	    				write "I am at : " + myself.oneCell.grid_x + ", " + myself.oneCell.grid_y + " Trying to move to: " + self.oneCell.grid_x + ", " + self.oneCell.grid_y;
	    				sightCell <- self.oneCell;
	    			}
	    			battleground target;
	    			float distance <- 1000.0;
	    			loop s over:sightCell.neighbours{
	    				float dist <- oneCell.location distance_to s.location;
	    				if dist < distance and dist!=0 and s.queen = nil{
	    					distance <- dist;
	    					target <- s;
	    				}
	    			}
	    			write "New Location is follows: " + target.grid_x + ", " + target.grid_y;
	    			oneCell.queen <- nil;
	    			oneCell <- target;
	    			location <- target.location;
	    			oneCell.queen <- self;
	    		}
	    	}
	    }
	}
    
    //REFLEXES
    reflex amIsafe when: !looking{
    	looking <- true;
    	do needToMove;
    	looking <- false;
    }

    aspect base {
        draw circle(1.0) color: #black ;
    }
    
}

grid battleground width: nQueen height: nQueen neighbors: nearbyQueen {
	list<battleground> neighbours  <- (self neighbors_at 2);
    royalEvent queen <- nil;
    init{
        add self to: tltCells;
    }
	
}
experiment Gala type: gui {
    output {
        display main_display {
            grid battleground lines: #black ;
            species royalEvent aspect: base ;
        }
    }
}
