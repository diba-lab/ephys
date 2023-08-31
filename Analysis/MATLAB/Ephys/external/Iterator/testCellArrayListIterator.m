%% Test Script for Class CellArrayListIterator
% Step through and execute this script cell-by-cell to verify the iterator
% for a CellArrayList.
%
% Written by Bobby Nedelkovski
% MathWorks Australia
% Copyright 2009-2010, The MathWorks, Inc.


%% Clean Up
clear classes
clc


%% Create 2x2 Array of Instances of CellArrayList
myList(2,2) = CellArrayList();


%% Append Arbitrary Elements to End of All Lists
myList.add(5);  % a single integer


%% Append Arbitrary Elements to End of Particular Groups of Lists
myList(1,1).add(rand(2));        % a 2x2 matrix
myList(1,:).add({50,55});        % 2 integers as 2 unique elements
myList(2,:).add({rand(3),5:7});  % a 3x3 matrix and a 1x3 array
myList(:,1).add(myList);         % reference to self!
myList(:,2).add({10,11;12,13});  % a 2x2 cell array
myList(2,2).add({150,160,170});  % 3 integers as 3 unique elements


%% Display 'myList'
% Alternatively, you can execute "myList.display()" which produces the same
% output.
myList


%% Create Iterator for Array of CellArrayLists
myIter = myList.createIterator();


%% Traverse First 3 Elements in All Lists
a = myIter.next()  % a = {5,5; 5,5}
b = myIter.next()  % b = {2x2 matrix,50; 3x3 matrix,3x3 matrix}
c = myIter.next()  % c = {50,55; 1x3 array,1x3 array}


%% Reset Iterator for Each List
myIter.reset();


%% Traverse All Elements of a Particular List
particularIter = myIter(1,2);
while particularIter.hasNext()
   elt = particularIter.next()
   % ...operations to perform on elt go in here...
end
% Reset iterator.
particularIter.reset();


%% Traverse All Elements of All Lists
hasNext = myIter.hasNext();
while any(hasNext(:))
   elts = myIter.next()
   % ...operations to perform on elts go in here...
   hasNext = myIter.hasNext();
end
% Reset iterators.
myIter.reset();


%%
% Alternative implementation of the same operation...
n = numel(myIter);
while any(reshape(myIter.hasNext(),n,1))
   elts = myIter.next()
   % ...operations to perform on elts go in here...
end


%% Check End Of Traversal of All Lists
% next = [0,0; 0,0] (matrix of falses)
next = myIter.hasNext()


%% Try Access Next Element
% This yields cell array of empty sets [ ] given we have already traversed
% all elements of each corresponding list.
elts = myIter.next()

