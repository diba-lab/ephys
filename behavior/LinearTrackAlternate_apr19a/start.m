clear all
configFile='config.csv';
w1=WaterWell('D2','D8',configFile);
w2=WaterWell('D3','D9',configFile);
mg=MagicalGarden(w1,w2);
mg=mg.setStates([1 0]);
mg.start();