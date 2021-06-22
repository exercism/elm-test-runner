// Link to compiled Elm code main.js
var Elm = require("./main").Elm;
var main = Elm.Main.init();

// Get data from stdin
var fs = require("fs");
var input = fs.readFileSync(0, "utf-8"); // 0 is stdin
//console.log("\n   Input: ", input)

// Send data to the elm app
main.ports.stdin.send(input);

// Get data from the elm app
main.ports.stdout.subscribe(function (output) {
  // send normalized code to stdout
  console.log(output);
});
