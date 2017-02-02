// Defining a typical quotes table
quote:([] time:`timestamp$(); `g#sym:`symbol$(); src:`symbol$(); bid:`float$(); ask:`float$(); bsize:`int$(); asize:`int$());

// Defining a typical trade table
trade:([] time:`timestamp$(); `g#sym:`symbol$(); src:`symbol$(); price:`float$(); amount:`int$(); side:`symbol$());

// Defining the table t to compare estimated values to -22! and \ts calculated values
t:([]date:`date$(); size:`long$(); price:`float$(); exch:`g#`char$());

// A dictionary of tables and counts.
counts:(!) . flip (	(`trade;1000000);
			(`quote;10000000);
			(`t;1000000))
