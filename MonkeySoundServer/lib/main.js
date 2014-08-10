var http = require('http');
var fs = require('fs');



function logRequest(req){
    console.log(req.files);
    console.log(req.headers['content-length'])

};

http.createServer(function(request,response){
   response.writeHead(200, {"Content-Type": "application/json"});
   if(request.method === 'GET'){
     response.end("Hello");

 }else{
  var destinationFile = fs.createWriteStream("destination.md");
  request.pipe(destinationFile);

  logRequest(request);

  var fileSize = request.headers['content-length'];
  var uploadedBytes = 0 ;

  request.on('data',function(d){

   uploadedBytes += d.length;
   var p = (uploadedBytes/fileSize) * 100;
   //response.write("Uploading " + parseInt(p)+ " %\n");

});

  request.on('end',function(){
   //response.end("File Upload Complete");
   response.end();
});
}


}).listen(9000,function(){

   console.log("server started");

});