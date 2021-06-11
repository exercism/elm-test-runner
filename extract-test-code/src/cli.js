
// Link to compiled Elm code main.js
var Elm = require('./main').Elm;
var main = Elm.Main.init();

// Get data from stdin
var fs = require("fs");
var input = fs.readFileSync(process.stdin.fd, "utf-8");
//console.log("\n   Input: ", input)

// Send data to the elm app
main.ports.get.send(input);

// Get data from the elm app
main.ports.put.subscribe(function (output) {
  // send normalized code to stdout
  console.log(output)
});

