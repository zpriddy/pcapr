/* Simple parser for MSL */

var MSLParser = Editor.Parser = (function() {
  var tokenizeMSL = (function() {
    function normal(source, setState) {
      var ch = source.next();
      if (ch == "#") {
        while (!source.endOfLine()) {
		    source.next();            
        }
        return "msl-comment";
      }
      else if (ch == "\"" || ch == "'" || ch == "/") {
        setState(inString(ch));
        return null;
      }
      else if (ch == "0" && source.equals("h")) {
        source.next();
        source.nextWhileMatches(/[a-fA-F0-9]/);
        return "msl-hex-string";
      }
      else if (ch == "0" && source.equals("b")) {
        source.next();
        source.nextWhileMatches(/[01]/);
        return "msl-bin-string";
      }
      else if (ch == "0" && source.equals("x")) {
        source.next();
        source.nextWhileMatches(/[a-fA-F0-9]/);
        return "msl-number";
      }
      else if (/\d/.test(ch)) {
        source.nextWhileMatches(/\d/);
        return "msl-number";
      }
      else if (ch === "&" && source.matches(/[a-zA-Z_]/)) {
	      source.nextWhileMatches(/[a-zA-Z0-9_]/);
	      return "msl-host";          
      }
      else if (ch === "$" && source.matches(/[a-zA-Z_]/)) {
	      source.nextWhileMatches(/[a-zA-Z0-9_]/);
	      return "msl-option";
      }
      else if (ch === "@" && source.matches(/[a-zA-Z_]/)) {
	      source.nextWhileMatches(/[a-zA-Z0-9_]/);
	      if (source.equals(".")) {
	        source.next();
  	      if (source.matches(/[a-zA-Z_]/)) {
  		      source.nextWhileMatches(/[a-zA-Z0-9_]/);
		      }
	      }
	      return "msl-variable";
      }
      else if (/[\[\]{}\(\),;\:\.]/.test(ch)) {
        return "msl-punctuation";	
      }
      else {
        source.nextWhileMatches(/[\w_]/);
        return "msl-identifier";
      }
    }

    function inString(quote) {
      return function(source, setState) {
        var escaped = false;
        while (!source.endOfLine()) {
          var ch = source.next();
          if (ch == quote && !escaped)
            break;
          escaped = !escaped && ch == "\\";
        }
        if (!escaped)
          setState(normal);
        return "msl-string";
      };
    }

    return function(source, startState) {
      return tokenizer(source, startState || normal);
    };
  })();

  function indentMSL(inBraces, base) {
    return function(nextChars) {
      var indent =  base + inBraces*indentUnit;
      if (/^[\}\]]/.test(nextChars))
        indent -= indentUnit;
      return indent;
    };
  }

  // This is a very simplistic parser 
  function parseMSL(source, basecolumn) {
    var keywords = /scenario|hosts|host|options|variables|random_bytes|random_integer|random_string|steps|assertions|((client|server)_(send|receive))/;
    
    basecolumn = basecolumn || 0;
    var tokens = tokenizeMSL(source);
    var inBraces = 0;
    var inAttr = false;

    var iter = {
      next: function() {
        var token = tokens.next(), style = token.style, content = token.content;

        if (style === "msl-identifier") {
          if (inAttr)
            token.style = "msl-property";
          else if (keywords.test(content))
            token.style = "msl-keyword";
          else if (/true|false/.test(content))
            token.style = "msl-boolean";
        } else if (style === 'msl-option' && inBraces === 2) {
          token.style = 'msl-option-def';
        } else if (style === 'msl-host' && inBraces === 2) {
            token.style = 'msl-host-def';
        } else if (style === 'msl-variable' && (inBraces === 2 || inBraces == 4)) {
          token.style = 'msl-variable-def';
        }
          
        if (content == "\n")
          token.indentation = indentMSL(inBraces, basecolumn);
          
        if (content == '(')
          inAttr = true;
        else if (content == ')')
          inAttr = false;

        if (content == "{" || content == "[")
          inBraces++;
        else if (content == "}" || content == "]")
          inBraces--;

        return token;
      },

      copy: function() {
        var _inBraces = inBraces, _inAttr = inAttr, _tokenState = tokens.state;
        return function(source) {
          tokens = tokenizeMSL(source, _tokenState);
          inBraces = _inBraces;
          inAttr = _inAttr;
          return iter;
        };
      }
    };
    return iter;
  }

  return {make: parseMSL, electricChars: "{}[]"};
})();
