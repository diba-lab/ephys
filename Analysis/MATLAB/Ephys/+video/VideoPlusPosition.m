classdef VideoPlusPosition
    %VIDEOPLUSPOSITION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Video
        Position
    end
    
    methods
        function obj = VideoPlusPosition(video,position)
            %VIDEOPLUSPOSITION Construct an instance of this class
            %   Detailed explanation goes here
            obj.Video = video;
            obj.Position = position;
        end
        
        function farmes_marked = getWindow(obj,range)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            vid=obj.Video;
            pos=obj.Position;
            
            numfr=seconds(diff(range))*vid.FrameRate;
            startfr=seconds(range(1))*vid.FrameRate;
            frames_read=[startfr startfr+numfr-1];
            frames=vid.read(frames_read);
            frames_marked=nan(size(frames));
            positions_marker=pos.Data(:,:,frames_read(1):frames_read(2));

            color=linspecer(numel(pos.Markers));
            for ifr=1:size(frames,4)
                frame=frames(:,:,:,ifr);
                posfs=positions_marker(:,1:(end-1),ifr);
                likelyhood=positions_marker(:,end,ifr);
                for imarker=1:size(posfs,2)
                    size1=ceil(likelyhood(imarker)*10);
                    frame=insertObjectAnnotation(frame,'circle', ...
                        [posfs(imarker,:) size1],pos.Markers{imarker}, ...
                        'Color','white');
                end
                imshow(frame)
%                 pause(1/vid.FrameRate/2);
                farmes_marked(:,:,:,ifr)=frame;
            end
        end
    end
end

