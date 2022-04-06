clear all;
configFile='config.csv';
w1=WaterWell('D2','D10',configFile,'D7'); % WaterWell(sensorPin, motorPin, configFile, markerPin)
w2=WaterWell('D3','D9',configFile,'D7');
w3=WaterWell('D4','D8',configFile,'D7');
mg=MagicalGarden(w1,w3);
mg=mg.setStates([1 0]);
mg.start();
