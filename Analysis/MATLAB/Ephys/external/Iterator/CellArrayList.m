classdef CellArrayList < List
   %CELLARRAYLIST A cell array realisation of the List ADT
   %   Refer to the description in the abstract superclass List for
   %   full detail.  This class is a concrete implementation of the List
   %   ADT - a useful 1D data structure for storing a heterogeneous set
   %   of elements.
   %
   %   Written by Bobby Nedelkovski
   %   MathWorks Australia
   %   Copyright 2009-2010, The MathWorks, Inc.
   
   % 2009-Oct-06: Remove property 'numElts' as it's defined in superclass.
   properties(Access=private)
      capacity;  % Capacity of pre-allocated list
      list;      % Flat Cell Array storage container for elements
   end
   
   % 2010-Apr-07: Define arbitrary size for initial list capacity.
   properties(Constant=true, GetAccess=private)
      INITIAL_CAPACITY = 10;
   end
   
   % 2010-Jul-20: Methods modified to work with arrays of CellArrayList.
   methods % Public Access
      % Constructor.
      function newObj = CellArrayList()
         % Use an arbitrary initial list capacity and pre-allocate.
         newObj.numElts  = 0;
         newObj.capacity = newObj.INITIAL_CAPACITY;
         newObj.list     = cell(newObj.capacity,1);
      end
      
      % Concrete implementation.  See List superclass.
      function numElts = length(obj)
         numElts = zeros(size(obj));
         % Use linear index to populate numElts array.
         for i = 1:numel(obj)
            numElts(i) = obj(i).numElts;
         end
      end
      
      % Concrete implementation.  See List superclass.
      function empty = isempty(obj)
         empty = zeros(size(obj));
         % Use linear index to populate empty array.
         for i = 1:numel(obj)
            empty(i) = obj(i).numElts==0;
         end
      end
      
      % Concrete implementation.  See List superclass.
      % NOTE:  This method accepts elements of any data type as input.
      % Using a cell array vector 'cav' will populate the list with
      % numel(cav) unique elements, otherwise the input will be treated as
      % a single element.
      function add(varargin)
         % Check correct number of input args.
         error(nargchk(2,3,nargin));
         
         % Extract input args.
         obj  = varargin{1};
         elts = varargin{2};
         if nargin == 3
            loc = varargin{3};
            assert(isnumeric(loc) && isscalar(loc) && floor(loc)==loc && loc>0,...
               'MATLAB:List:CellArrayList','Location must be a positive scalar integer.');
         else
            % If no location parameter supplied, append elements to end of
            % list.
            loc = inf;
         end
         
         % The elements of a single row or column cell array will be stored
         % as unique elements in the list.
         if iscell(elts) && isvector(elts)
            % Get number of new elements.
            n = numel(elts);
         else
            n = 1;
            elts = {elts};
         end

          % Use linear index to populate each list.
         for i = 1:numel(obj)
            obji = obj(i);
            
            % If location parameter exceeds the #elements+1 for a
            % particular list, simply append to end of list.
            if loc > obji.numElts+1
               loci = obji.numElts+1;
            else
               loci = loc;
            end
            
            % 2010-Apr-07: Bug fix to avoid infinite while-loop when
            % capacity reaches 0.  This occurs when capacity = numElts and
            % remove() is called numElts consecutive times to reduce
            % capacity to 0.
            if obji.capacity == 0
               % Re-initialise the list.
               obji.capacity = obji.INITIAL_CAPACITY;
               obji.list     = cell(obji.capacity,1);
            end
         
            % Ensure sufficient space is available for new elements.
            resizeRequired = false;
            while n > obji.capacity-obji.numElts
               obji.capacity = 2*obji.capacity;
               resizeRequired = true;
            end
         
            % If the capacity was re-sized, create new list otherwise place
            % new elements in the existing list.
            % ***NOTE: Assignment by parts is more memory efficient than
            % concatenating parts to assign by whole.
            if resizeRequired
               tempList = cell(obji.capacity,1);
               tempList(1:loci-1) = obji.list(1:loci-1);
               tempList(loci:loci+n-1) = elts;
               % Existing elements in the list may be shifted to make way for
               % the new elements.
               if loci <= obji.numElts
                  tempList(loci+n:obji.numElts+n) = obji.list(loci:obji.numElts);
               end
               obji.list = tempList;
            else
               % Shift existing elements to end of list prior to inserting
               % the new elements in place.
               if loci <= obji.numElts
                  obji.list(loci+n:obji.numElts+n) = obji.list(loci:obji.numElts);
               end
               obji.list(loci:loci+n-1) = elts;
            end
            
            % Save new total number of elements.
            obji.numElts = obji.numElts+n;
         end
      end
      
      % Concrete implementation.  See List superclass.
      % NOTE:  The input 'locs' is a scalar or 1D array of integers
      % i.e. [1,2,3]
      function elts = get(obj,locs)
         % Check input args.
         assert(isnumeric(locs) && isvector(locs) && isequal(floor(locs),locs) && all(locs > 0),...
            'MATLAB:List:CellArrayList','Locations must be vector of positive integers.');
         
         elts = cell(size(obj));

         % Define cell array or regular array indexing into list.
         if numel(locs) > 1
            felts = @(i) obj(i).list(locs);
         else
            felts = @(i) obj(i).list{locs};
         end
         
         for i = 1:numel(obj)
            % If a particular list is empty or a location exceeds the
            % length of the list, provide an empty array.
            n = obj(i).numElts;
            if n ~= 0 && all(locs <= n)
               elts{i} = felts(i);
            end
         end
         
         % Return single element if only single element extracted.
         if numel(elts) == 1
            elts = elts{:};
         end
      end
      
      % Concrete implementation.  See List superclass.
      % NOTE:  The input 'locs' is a scalar or 1D array of integers
      % i.e. [1,2,3]
      function elts = remove(obj,locs)
         elts = obj.get(locs);
         if iscell(elts)
            eltst = elts;
         else
            eltst = {elts};
         end
                  
         % 2009-Oct-06: Bug fix exclude duplicate locations from the
         % total count of removed elements.
         n = numel(unique(locs));
         
         % Automatically remove and shift down existing elements in same
         % contiguous memory space for each list.
         for i = 1:numel(obj)
            if ~isempty(eltst{i})
               obj(i).list(locs) = [];
               obj(i).numElts = obj(i).numElts-n;
               obj(i).capacity = obj(i).capacity-n;
            end
         end
      end

      % Concrete implementation.  See List superclass.
      function count = countOf(obj,elt)
         count = zeros(size(obj));
         locs = obj.locationsOf(elt);
         if ~iscell(locs)
            locs = {locs};
         end

         % Use linear index to populate count array.
         for i = 1:numel(obj)
            count(i) = numel(locs{i});
         end
      end
      
      % Concrete implementation.  See List superclass.
      function locs = locationsOf(obj,elt)
         locs = cell(size(obj));
         % Use linear index to populate locs cell array.
         for i = 1:numel(obj)
            locs{i} = find(cellfun(@(c) isequal(c,elt),obj(i).list));
         end
         % Return numerical array if single list operation.
         if numel(locs) == 1
            locs = locs{:};
         end
      end
      
      % Overloaded.  Specialised display method.
      % 2010-Jul-20: If this obj is an array of CellArrayLists then display
      % each in order.
      function display(obj)
         % Use linear index to identify each list in array.
         for i = 1:numel(obj)
            fprintf('\n***List #%d***\n',i);
            celldisp(obj(i).list(1:obj(i).numElts),['list[' int2str(i) ']']);
         end
         fprintf('\n');
      end
      
      % Specialised method to return an iterator array for this list array.
      % 2010-Jul-27: Modified to return array of CellArrayListIterators of
      % the same dimensionality as the array of CellArrayLists.
      function iter = createIterator(obj)
         % Pre-allocate array of CellArrayListIterators to empty
         % CellArrayLists.
         iter = repmat(CellArrayListIterator(),size(obj));
         
         % Use linear index to populate CellArrayListIterator array.
         for i = 1:numel(obj)
            iter(i) = CellArrayListIterator(obj(i));
         end
      end
   end % methods
end % classdef
