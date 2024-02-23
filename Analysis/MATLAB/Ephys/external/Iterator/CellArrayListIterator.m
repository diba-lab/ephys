classdef CellArrayListIterator < Iterator
   %CELLARRAYLISTITERATOR Realisation of Iterator OOP Design Pattern
   %   Refer to the description in the abstract superclass Iterator for
   %   full detail.  This is implemented as an external/active iterator.
   %   This class leverages code from MATLAB File Exchange Item "Data
   %   Structure: A Cell Array List Container" with modification to class
   %   CellArrayList to include a method for returning an instance
   %   of its iterator.
   %   The benefits in using an iterator for a CellArrayList may not be so
   %   obvious since it is easy enough to index through the list using a
   %   simple counter.  It's usage becomes clear in the case of a Linked
   %   List or Doubly Linked List ADT where the detail in accessing
   %   elements may prove cumbersome. 
   %
   %   Written by Bobby Nedelkovski
   %   MathWorks Australia
   %   Copyright 2009-2010, The MathWorks, Inc.
   
   % 2009-Oct-06: Remove property 'collection' as it's defined in superclass.
   properties(Access=private)
      loc;  % Location of traversal
   end
   
   % 2010-Jul-27: Methods modified to work with arrays of
   % CellArrayListIterator.
   methods % Public Access     
      % Constructor.
      function newObj = CellArrayListIterator(varargin)
         % Check correct number of input args.
         error(nargchk(0,1,nargin));
         
         if nargin == 0
            % Store reference to empty list by default and position
            % iterator at start.
            newObj.collection = CellArrayList();
            newObj.loc        = 1;
         else
            % Store reference to list and position iterator at start.
            newObj.collection = varargin{1};
            newObj.loc        = 1;
         end
      end
      
      % Concrete implementation.  See Iterator superclass.
      function elts = next(obj)
         elts = cell(size(obj));
         % Query all lists for next element.
         hasNext = obj.hasNext();
         
         % Use linear index to retrieve next element from each
         % CellArrayList.
         for i = 1:numel(obj)
            if hasNext(i)
               elts{i} = obj(i).collection.get(obj(i).loc);
               obj(i).loc = obj(i).loc + 1;
            end
         end

         % Return single element if only single element extracted.
         if numel(elts) == 1
            elts = elts{:};
         end
      end
      
      % Concrete implementation.  See Iterator superclass.
      function next = hasNext(obj)
         next = zeros(size(obj));
         % Use linear index to populate next array.
         for i = 1:numel(obj)
            next(i) = obj(i).loc <= obj(i).collection.length();
         end
      end
      
      % Concrete implementation.  See Iterator superclass.
      function reset(obj)
         % Position iterator at start for each CellArrayList.
         for i = 1:numel(obj)
            obj(i).loc = 1;
         end
      end
   end % methods
end % classdef
