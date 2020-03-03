import dproc from './data_proc.js';
import plot from './plot.js';
import dbgdata from './debugdata.js';
import * as spng from 'save-svg-as-png';

export function handleFiles(files) {
  let fileInput = document.getElementById('tPA-input');
  let file = files[0];
  let textType = /text.*/;

  // Clear existing outputs
  let outsec = document.getElementById("output-section");
  while(outsec.firstChild){
    outsec.removeChild(outsec.firstChild);
  }

  try{
    let reader = new FileReader();
    reader.onload = function(e) { procAndUpdate(reader.result); }
    reader.readAsText(file);	
  }
  catch(err){
    console.log(err);
  }
}

export function errorDisplay(err){
  let outsec = document.getElementById("output-section");
  let error_element = document.createElement("P");
  error_element.innerHTML = "Error Occured:\n"+err+"\n";
  outsec.appendChild(error_element);
}

export function procAndUpdate(res){
  // Check the input data
  // let data_check = dproc.checkdata(res);
  
  try{
    // get the processed data
    let processed_data = dproc.processData(res);

    // Clear any existing output and save button
    let efig = document.getElementById("tpafigure");
    let ebtn = document.getElementById("save-btn");
    if(efig){efig.remove();}
    if(ebtn){ebtn.remove();}

    // plot the processed data
    plot.plotResults(processed_data);

    // Add Save As Button to output section
    document.getElementById("button-section")
      .appendChild( document.createElement("div") )
      .appendChild(saveAsButton());
  }
  catch(err){
    errorDisplay(err);
  }
  // Add a table
  //plot.tabulate(processed_data);
}

export function dbgload(){
  let u = new URL(window.location.href);
  if(u.searchParams.get("debug") == "true"){
    let res = dbgdata.dbgdata();
    procAndUpdate(res);
  }
}

function saveAsButton(){
  let e = document.createElement("button");
  e.setAttribute("type","button");
  e.setAttribute("id","save-btn");
  e.setAttribute("onclick", "bndl.downloadFig()");
  e.innerText = "Download PNG";

  return(e);
}

export function downloadFig(){
  spng.saveSvgAsPng(document.getElementById("tpafigure"), "stroke-ready-tpa.png");
}
