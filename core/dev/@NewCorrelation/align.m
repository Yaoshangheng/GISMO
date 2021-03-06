function c = align(c, alignfreq)
   %align   resample traces so that a sample falls exactly on trigger time.
   %
   % c = ALIGN(c)
   % This function resamples the traces in a correlation object so that one
   % sample falls precisely on the trigger time. By aligning the samples in
   % adjacent traces, traces can be stacked, differenced or otherwise
   % manipulated sample by sample.
   %
   % c = ALIGN(c,ALIGNFREQ)
   % Specify a new sampling frequency for the data.
   %
   % NOTE: Most applications will not require a direct call to this routine.
   % It is used internally by several correlation routines. Note the slightly
   % different usage than waveform/align. The correlation version is
   % hardwired to align on the trigger time.
   
   % Author: Michael West, Geophysical Institute, Univ. of Alaska Fairbanks
   % $Date$
   % $Revision$
   
   narginchk(1,2)
   
   if ~exist('alignfreq','var')
      alignfreq = c.samplerate;
   end
   
   % CALL TRACE/ALIGN
   c.traces = align(c.traces, c.trig, alignfreq);
   c = unifytracelengths(c);
end




