classdef ThetaPeakCombined
    %THETAPEAKCOMBINED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        thpkList
    end
    
    methods
        function obj = ThetaPeakCombined(thpk)
            %THETAPEAKCOMBINED Construct an instance of this class
            %   Detailed explanation goes here
            obj.thpkList=CellArrayList();
            try
                obj.thpkList.add(thpk);
            catch
            end
        end
        
        function obj = plus(obj,thpk)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.thpkList.add(thpk);
        end
        function newthpks = merge(obj,thpks)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            newthpks=ThetaPeakCombined;
            for il=1:obj.thpkList.length
                thpk1=obj.thpkList.get(il);
                thpk2=thpks.thpkList.get(il);
                thpkmsum=thpk1.merge(thpk2);
                newthpks=newthpks+thpkmsum;
            end
%             try close(7);catch, end; figure(7);obj.plotCF
%             try close(8);catch, end;figure(8);thpks.plotCF
%             try close(9);catch, end;figure(9);newthpks.plotCF
        end
        function axsr=plotCF(obj,rows,row)
            if ~exist('rows','var')
                rows=1; 
            else
                if isa(rows,'matlab.graphics.axis.Axes');
                    axs=rows;
                end
            end
            
            if ~exist('row','var')
                row=1;
            end
            list=obj.thpkList;
            for isub=1:list.length
                if exist('axs','var')
                    axes(axs(isub)); %#ok<LAXES>
                    hold on
                else
                    subplot(rows, list.length, (row-1)*list.length + isub)
                end
                thesub=list.get(isub);
                if ~isempty(thesub.Signal)
                    thesub.plotCF
                end
                if isub>1
                    xlabel('');
%                     xticks([]);
                end
                axsr(isub)=gca;
            end            
        end
        function plotPW(obj)
            list=obj.thpkList;
            for isub=1:list.length
                subplot(1, list.length,isub)
                thesub=list.get(isub);
                thesub.plotPW
            end            
        end
    end
end

