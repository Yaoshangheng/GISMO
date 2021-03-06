function allObj = load_file(ds,searchClass,scnl,startt,endt)
   %grab all the variables in a matlab file, and flip through them, returning
   %those that match the criteria
   % allObj = load_file(datasource,searchClass,scnl,starttime,endtime)
   %   DATASOURCE is a single datasource object (of type "file")
   %   SEARCHCLASS is a string containing the name of the class you are
   %   searching for.  eg, 'double','waveform', etc.
   %   SCNL is an array of scnlobjects which hold
   %   station/channel/network/location matches.
   %   STARTTIME is the starting time in matlab datenum format
   %   ENDTIME is the ending time in matlab datenum format
   %
   %   This function returns a 1xN dimesional array of all relevent objects
   %   found within the searched file(s).  All variable identity from within
   %   the files is lost.
   %   - - -
   %   SO, for example, in the context of searching for waveform data...
   %   if there is a searchfile, that contians the variables: W (1x3
   %   waveform), W2 (1x1 waveform), MyWc (2x2 cell with waveforms in it), and
   %   D (double).
   %
   %   the load_file method will rip out each and every waveform (recursing
   %   through cells), then lump all of them into a large 1xN waveform.  Each
   %   waveform that doesn't meet the SCNL criteria is discarded.  Then, all
   %   waveforms that don't have data somewhere within the starttime-endtime
   %   timeframe will be discarded as well.
   %
   %   It is important to note that the recovered objects aren't trimmed to
   %   the starttime-endtime timeeframe.  That is, individual objects are not
   %   altered through the use of this function.
   %
   %
   % Any object can be loaded from file, however since this was designed to
   % work with seismic data, it must have an ISMEMBER function that takes as
   % it's parameters the object itself and a SCNLobject.  Also required is the
   % [Starts Ends] = GETTIMERANGE(obj) function. (see waveform/gettimerange
   % for an example implementation.
   %
   % see also ISMEMBER, WAVEFORM/GETTIMERANGE
   error('Should never call this function');
   %The file looks a little opaque because it deals generically with classes
   %and objects, rather than tying itself down to any particular object.
   allfilen = getfilename(ds,scnl,startt);
   for thisfile = 1 : numel(allfilen)
      filen = allfilen{thisfile};
      stuff=  load(filen);
      fieldn = fieldnames(stuff);
      
      %Look through all variables that were loaded, looking for the desired
      %class.  If a cell is encountered, then look for occurrences of that class
      %within the cell (recursively).
      
      myObjectMask = false(size(fieldn));
      holder = cell(size(fieldn));
      for fieldidx = 1:numel(fieldn)
         thisfield =  fieldn{fieldidx};
         %grab all myObjects
         if isa(stuff.(thisfield),searchClass)
            holder(fieldidx) = {reshape(stuff.(thisfield),1,numel(stuff.(thisfield)))};
            myObjectMask(fieldidx) = true;
            stuff.(thisfield) = {};
         elseif isa(stuff.(thisfield),'cell')
            holder(fieldidx) = {getFromCells(searchClass,stuff.(thisfield))};
            myObjectMask(fieldidx) = true;
         else
            stuff.(thisfield) = {};
         end
      end
      myObj = [holder{myObjectMask}];
      myObj = myObj(ismember(myObj,scnl));
      
      
      %now get rid of any that don't match the time criteria.
      hasValidRange = isWithinTimeRange(myObj,startt,endt);
      allObj(thisfile) = {myObj(hasValidRange)};
      
      
   end
   allObj = [allObj{:}];
end

function hasValidRange = isWithinTimeRange(myObj,startt,endt)
   
   [theseStarts theseEnds] = gettimerange(myObj);
   hasValidRange = false(size(theseStarts));
   
   %   if isempty(theseStarts) || isempty(theseEnds)
   %     warning('Datasource:ObjectNoTimes',...
   %       'One or more objects have no start or end times associated with them');
   %     return;
   %   end
   
   %check each object's range against all requested ranges
   for timeidx = 1:numel(startt)
      requestedStart = startt(timeidx);
      requestedEnd = endt(timeidx);
      
      % make sure the data doesn't start AFTER requested data...
      validStarts = (theseStarts <=requestedEnd);
      % ...and make sure the data deosn't end BEFORE requested data
      validEnds = (theseEnds >= requestedStart);
      
      %add objects that match the criteria to the OK list
      hasValidRange = hasValidRange | (validStarts & validEnds);
   end
end


function mObj = getFromCells(searchClass, mycell)
   % returns an 1xN array of objects
   
   %might break if searchClass == 'cell'. but I haven't tested it
   searchFn = @(x) isa (x, searchClass);
   makeRows = @(x) reshape(x,1,numel(x));
   
   target = cellfun(searchFn, mycell);
   objs = cellfun(makeRows, mycell(target), 'uniformoutput', false);
   
   holdsCell = cellfun(@iscell, mycell);
   if any(holdsCell)
      mObj = getFromCells(searchClass, mycell{holdsCell}); %recurse
   else
      mObj = {};
   end
   
   mObj = [mObj{:} objs{:}];
end
   
   %{
   holdsTarget = false(size(mycell));
   for i=1:numel(mycell);
      holdsTarget(i) = isa(mycell{i}, searchClass);
      if isa(mycell{i},searchClass),
         holdsTarget(i) = true;
         mycell(i) = {reshape(mycell{i},1,numel(mycell{i}))}; %make all myObjects 1xN
      elseif isa(mycell{i},'cell') %it's a cell, let's recurse
         mycell(i) = {myObjectsFromCells(mycell{i})};  %pull myObjects from the cell and bring them to this level.
      end
   end
   mObj= [mycell{holdsTarget}];
end
%}
