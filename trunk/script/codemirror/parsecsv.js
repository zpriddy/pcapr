/* Simple parser for CSV */

var CSVParser = Editor.Parser = (function() {
    var tokenizeCSV = (function() {
        function normal(source, setState) {
            var ch = source.next();
            if (ch === "#") {
                while (!source.endOfLine()) {
                    source.next();                        
                }
                return "msl-comment";
            } else if (ch === "\"") {
                setState(inString(ch));
                return null;
            } else if (ch === ',') {
                return "csv-comma";
            } else if (ch === '\n') {
                return "csv-eol";
            } else {
                source.nextWhileMatches(/[^,\r\n"]/);
                return "csv-token";
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
    
    function indentCSV(base) {
        return function(nextChars) {
            return base;
        }
    };

    // This is a very simplistic parser 
    function parseCSV(source, basecolumn) {
        basecolumn = basecolumn || 0;
        var tokens = tokenizeCSV(source);
        var startOfLine = true;
        var inOptions = false;

        var iter = {
            next: function() {
                var token = tokens.next(), style = token.style, content = token.content;
                
                if (startOfLine) {
                    if (token.style === 'csv-token') {
                        if (/^options|defaults|(test.*)$/.test(content)) {
                            token.style = "msl-option";
                        }

                        if (content === 'options') {
                            inOptions = true;
                        }                        
                    }
                } else if (inOptions === true) {
                    token.style = "msl-keyword";                    
                }
                
                if (content === '\n') {
                    token.indentation = indentCSV(basecolumn);
                    startOfLine = true;
                    inOptions = false;
                } else {
                    startOfLine = false;
                }
                return token;
            },

            copy: function() {
                var _startOfLine = startOfLine, _inOptions = inOptions, _tokenState = tokens.state;
                return function(source) {
                    tokens = tokenizeCSV(source, _tokenState);
                    startOfLine = _startOfLine;
                    inOptions = _inOptions;
                    return iter;
                };
            }
        };
        return iter;
    }

    return { make: parseCSV };
})();
