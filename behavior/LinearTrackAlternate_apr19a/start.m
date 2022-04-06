clear all;
configFile='config.csv';
config_io
w1=WaterWell('D2','D8',configFile,'D4');
w2=WaterWell('D3','D9',configFile,'D4');
mg=MagicalGarden(w1,w2);
mg=mg.setStates([1 0]);
mg.start();
