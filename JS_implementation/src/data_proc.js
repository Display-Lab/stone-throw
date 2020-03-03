import {csvParse} from 'd3-dsv';
import {nest} from 'd3';
import datefns from 'date-fns';
import * as d3array from 'd3-array';


var EXPECTEDHEADER= ["year", "month", "case", "Door to Dr Contact", "Door to CT", "CT End to Read", "CBC order to Result", "INR order to result", "Door to Needle", "tPA order to tPA delivered time"]

const compareArrays = (a, b) => a.map(JSON.stringify).join() === b.map(JSON.stringify).join();

function verifyHeader( arr ){
  return( compareArrays(arr, EXPECTEDHEADER) );
}

export function processData(text) {
  let pdata = csvParse(text);
  let cols = pdata[0];

  // check for expected columns
  if(verifyHeader(pdata.columns) === true){
    console.log( "Good Header" );
    let pd = calculatePlotData( pdata );
  }else{
    console.log( "Bad Header" );
    throw( 
      new Error("Headers did not match expected:\n"+JSON.stringify(EXPECTEDHEADER))
    );
  }

  // add date and date_str columns
  pdata.forEach(add_date_cols);

  // calculate the full date groups 
  let roll_qs = rolling_quarters( pdata.map( (v) => {return(v.date);}) ); 

  // Lookup the date group (rolling quarter) for each row.
  lookup_quarter_cols(pdata, roll_qs);

  // Summarize by rolling quarter
  let grouped_data = nest()
                      .key( (v)=>{return(v.quart.idx)} )
                      .entries(pdata);

  let filtered_data = grouped_data.filter((v)=>{return(v.key<4)});

  let summarized_data = filtered_data.map( summarize_row );

  console.log("done");
  return(summarized_data);
}

function summarize_row(row){
  let result = {};
  result.med_d2dr = d3array.median(row.values, (x)=>{return(x["Door to Dr Contact"])});
  result.med_d2ct = d3array.median(row.values, (x)=>{return(x["Door to CT"])});
  result.med_d2rx = d3array.median(row.values, (x)=>{return(x["Door to Needle"])});
  result.qtr_id = row.key;
  result.qtr_begin = datefns.format(row.values[0].quart.start, 'YYYY MMM');
  result.qtr_end = datefns.format(row.values[0].quart.end, 'YYYY MMM');

  let start_month = datefns.format(row.values[0].quart.start, 'MMM');
  let end_month = datefns.format(row.values[0].quart.end, 'MMM');
  let end_year = datefns.format(row.values[0].quart.end, 'YYYY');

  result.qtr_label=start_month+"-"+end_month+"\n"+end_year;

  return(result);
}

// Modify arr in place to add date columns
function add_date_cols(val, idx, arr){
  val.date = new Date(val.year, val.month -1);
  val.date_str = val.year + val.month;
  arr[idx] = val;
}

// Modify arr in place to add quarter information
function lookup_quarter_cols(data, lookup){
  for(let i=0; i<data.length; i++){
    let val = data[i];
    let quart = lookup.find(
      (lkup)=>{return(lkup.end >= val.date && val.date >= lkup.start)} 
    ); 
    val.quart = quart;
    data[i]=val;
  }
}

// Make a array of rolling quarters going back to before min date in data
function rolling_quarters( dates ){
  let maxdt = datefns.max(...dates);
  let mindt = datefns.min(...dates);
  let rows = [];

  let i=0;
  let quarter_start = maxdt;
  for(i=0; quarter_start > mindt; i++){
    let end_month   = maxdt.getMonth() - (i*3);
    let start_month = maxdt.getMonth() - (i*3) - 2;
    let quarter_end = month_ceil(new Date(maxdt.getFullYear(), end_month, 1));
    quarter_start = new Date(maxdt.getFullYear(), start_month, 1);
    rows.push( {start: quarter_start, end: quarter_end, idx: i} );
  }
  return(rows);
}

function month_ceil(dt){
  return(new Date(dt.getFullYear(), dt.getMonth()+1, 0));
}

function calculatePlotData( data ){
  return(true);
  // dates in the form yyyy-mm
  let dates = arr.map( element => { return(new Date(element[0], element[1])) });
  let date_strs = arr.map( element => { return(element[0] + "-" + element[1]) });

  let date_group_lookup = time_group_set( dates );
  console.log(date_group_lookup);

}

export default {processData};
