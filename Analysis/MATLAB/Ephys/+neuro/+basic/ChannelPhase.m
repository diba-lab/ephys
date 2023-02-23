classdef ChannelPhase<neuro.basic.ChannelProcessed
    %CHANNELPHASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = ChannelPhase(obj1)
            %CHANNELPHASE Construct an instance of this class
            %   Detailed explanation goes here
            fnames=fieldnames(obj1);
            for ip=1:numel(fnames)
                obj.(fnames{ip})=obj1.(fnames{ip});
            end
        end
        function []=plot(obj)
            phases=obj.Values;
            time=obj.TimeIntervalCombined;
            try
                t=minutes(time.getTimePointsZT);
            catch ME
                t=minutes(time.getTimePoints);
            end
            numcolors=64;
            colors = [0.9612 0.4459 0.4459;0.9475 0.4615 0.4019;0.9305 0.4783 0.3598;0.9102 0.4963 0.3201;0.887 0.5154 0.283;0.8611 0.5352 0.2489;0.8326 0.5557 0.2183;0.8019 0.5765 0.1913;0.7692 0.5977 0.1683;0.7349 0.6188 0.1494;0.6993 0.6397 0.1348;0.6628 0.6603 0.1248;0.6256 0.6803 0.1193;0.5882 0.6995 0.1184;0.5509 0.7178 0.1222;0.5141 0.7349 0.1306;0.4781 0.7507 0.1435;0.4433 0.7651 0.1608;0.41 0.7779 0.1823;0.3785 0.789 0.2079;0.3492 0.7982 0.2372;0.3222 0.8056 0.27;0.298 0.8109 0.306;0.2766 0.8143 0.3449;0.2584 0.8155 0.3861;0.2435 0.8147 0.4295;0.232 0.8118 0.4745;0.224 0.8069 0.5207;0.2197 0.8 0.5676;0.219 0.7912 0.6149;0.222 0.7805 0.662;0.2286 0.7681 0.7086;0.2388 0.7541 0.7541;0.2525 0.7385 0.7981;0.2695 0.7217 0.8402;0.2898 0.7037 0.8799;0.313 0.6846 0.917;0.3389 0.6648 0.9511;0.3674 0.6443 0.9817;0.4024 0.623 1;0.4432 0.6022 1;0.4802 0.5833 1;0.5146 0.5658 1;0.5472 0.5492 1;0.5787 0.5332 1;0.6098 0.5173 1;0.6411 0.5014 1;0.6732 0.485 1;0.7068 0.4679 1;0.7427 0.4496 1;0.782 0.4296 1;0.8215 0.411 0.9921;0.8508 0.4018 0.9628;0.8778 0.3944 0.93;0.902 0.3891 0.894;0.9234 0.3857 0.8551;0.9416 0.3845 0.8139;0.9565 0.3853 0.7705;0.968 0.3882 0.7255;0.976 0.3931 0.6793;0.9803 0.4 0.6324;0.981 0.4088 0.5851;0.978 0.4195 0.538;0.9714 0.4319 0.4914];
            phaseidx=round(normalize(phases,'range',[.5+eps numcolors+.5-.0001]));
            color=colors(phaseidx,:);
            filtered=obj.parent;
            try 
                original=filtered.parent;
                original.plot
                hold on;
            catch ME
                
            end
            filtered.plot
            hold on
            scatter(t,filtered.Values,10,color,"filled")
            hold off
        end
    end
end

