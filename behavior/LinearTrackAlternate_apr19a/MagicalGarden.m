classdef MagicalGarden
    %WATERWELLLIST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        waterWells
    end
    
    methods
        function obj = MagicalGarden(varargin)
            %WATERWELLLIST Construct an instance of this class
            %   Detailed explanation goes here
            obj.waterWells=WaterWell.empty;
            tr=Track.instance;
            for i=1:nargin
                aWell=varargin{i};
                obj.waterWells(i)=aWell;
            end
            for i=1:nargin
                aWell=obj.waterWells(i);
                l=aWell.addlistener('Watered',@(srcobj,wateredEvent)obj.updateStates());
                l=aWell.addlistener('Watered',@(srcobj,wateredEvent)tr.add(2,wateredEvent));
                l=aWell.addlistener('Touched',@(srcobj,touchedEvent)tr.add(1,touchedEvent));
            end
            fprintf('Magical Garden with %d wells is created.\n',nargin)
        end
        function []=start(obj)
            fprintf('The magical garden was started.\n')
            while true
                for i=1:numel(obj.waterWells)
                    theWell=obj.waterWells(i);
                    theWell.checkAndIfWater();
                    pause(.01);
                end
                pause(.01)
            end
        end
        
        function [obj]=updateStates(obj)
            states=obj.getStates();
            obj=obj.setStates(flip(states));
        end
        function states=getStates(obj)
            states=false(numel(obj.waterWells),1);
            for i=1:numel(obj.waterWells)
                aWaterWell=obj.waterWells(i);
                states(i)=aWaterWell.isActive;
            end
        end
        function obj=setStates(obj, states)
            for i=1:numel(obj.waterWells)
                aWaterWell=obj.waterWells(i);
                if states(i)
                    aWaterWell.activate();
                else
                    aWaterWell.deactivate();
                end
                obj.waterWells(i)=aWaterWell;
            end
            fprintf('States updated.\n   %d %d\n',states);
        end
        function obj = giveWater(obj)
            %giveWater Summary of this method goes here
            %   Detailed explanation goes here
            obj.waterWells(end+1) = waterWell;
        end
    end
end

