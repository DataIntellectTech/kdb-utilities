\d .sfgrowth
distinctratio:{[d]
   // Create a column, distinctpercent, which is a percentage of distinct values to total values for a given day 
   `distinctpercent xdesc update distinctpercent:100*distinctcount%counter from 
	raze {[d;x] 
   	   	raze {[t;d;c] 
			// Create a table containing counter (table count), distinctcount (number of distinct values)
			// column name and table name.
			update colname:c, tab:t from 
			// Extract symbol type columns and perform a functional select for each table in tables[] to extract count and distinct count
			eval (?;t;enlist enlist (=;`date;(last;d));0b;`counter`distinctcount!((#:;c);(#:;(?:;c))))}[x;d] each exec c from 
			meta value x where (t="s")or c=`sym}[d;] each tables[]}



growthrate:{[sd;ed]
  // Generate table t by iterating over tables[]
  t:{[sd;ed;x;y]
   
   // Extract a list of symbol columns for current table (y)
   symcols:exec c from meta value y where t="s";
   
   // Functional select to get distinct symbols from all symbol columns, by date, within given date range
   r:?[value y;enlist (within;`date;(enlist;`sd;`ed));(enlist `date)!enlist `date;symcols!distinct,/:symcols];
   
   // Apply lambda to a set of symbols for each day to obtain new symbols & recreate table r with only new symbols each day
   r:(key r)!flip cols[value r]!{x except' prev (union\)x} each value flip value r;
   
   // Generate a table containing nested lists of column names and counts of new symbols in those columns,
   // then ungroup the resulting table to give one record per column
   r:ungroup 0!([col:cols value r] date:(count cols value r)#enlist (0!r)`date;cnt:count each' value flip value r);
   
   // Get the total count of records in this table for each date, lj onto above table and add a field with table name
   // Upsert to x i.e. maintained state for over
   x upsert (update tab:y from r) lj select total:count i by date from value y
   
   // Use over to iterate through all tables, while maintaining state
   }[sd;ed]/[();tables[]];
  
   // Filter out initial date, calculate percentage new, order by percentage new & reorder columns
   `col`date`tab`cnt`total`percent xcols `percent xdesc update percent:100*cnt%total from select from t where date > sd}
