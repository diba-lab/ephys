classdef SDColors
    %SDCOLORS Summary of this class goes here
    %   Detailed explanation goes here
    properties
      RGB
   end
   methods
      function c = SDColors(r, g, b)
         c.RGB = [r g b]/255;
      end
   end
    enumeration
        ROL (102, 153, 255)
        CTRL (51, 153, 51)
        OCT (128, 0, 0)
        NSD (0, 0, 0)
        
        AWAKE (0, 0, 0)
        QWAKE (0, 0, 0)
        SWS (0, 0, 0)
        REM (0, 0, 0)
    end
end

