(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}




// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**_UNUSED/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**_UNUSED/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**/
	if (typeof x.$ === 'undefined')
	//*/
	/**_UNUSED/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0 = 0;
var _Utils_Tuple0_UNUSED = { $: '#0' };

function _Utils_Tuple2(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2_UNUSED(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3_UNUSED(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr(c) { return c; }
function _Utils_chr_UNUSED(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil = { $: 0 };
var _List_Nil_UNUSED = { $: '[]' };

function _List_Cons(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons_UNUSED(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log = F2(function(tag, value)
{
	return value;
});

var _Debug_log_UNUSED = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString(value)
{
	return '<internals>';
}

function _Debug_toString_UNUSED(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash_UNUSED(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.aJ.an === region.aP.an)
	{
		return 'on line ' + region.aJ.an;
	}
	return 'on lines ' + region.aJ.an + ' through ' + region.aP.an;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**_UNUSED/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap_UNUSED(value) { return { $: 0, a: value }; }
function _Json_unwrap_UNUSED(value) { return value.a; }

function _Json_wrap(value) { return value; }
function _Json_unwrap(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.bC,
		impl.bQ,
		impl.bM,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**_UNUSED/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**/
	var node = args['node'];
	//*/
	/**_UNUSED/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS
//
// For some reason, tabs can appear in href protocols and it still works.
// So '\tjava\tSCRIPT:alert("!!!")' and 'javascript:alert("!!!")' are the same
// in practice. That is why _VirtualDom_RE_js and _VirtualDom_RE_js_html look
// so freaky.
//
// Pulling the regular expressions out to the top level gives a slight speed
// boost in small benchmarks (4-10%) but hoisting values to reduce allocation
// can be unpredictable in large programs where JIT may have a harder time with
// functions are not fully self-contained. The benefit is more that the js and
// js_html ones are so weird that I prefer to see them near each other.


var _VirtualDom_RE_script = /^script$/i;
var _VirtualDom_RE_on_formAction = /^(on|formAction$)/i;
var _VirtualDom_RE_js = /^\s*j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i;
var _VirtualDom_RE_js_html = /^\s*(j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:|d\s*a\s*t\s*a\s*:\s*t\s*e\s*x\s*t\s*\/\s*h\s*t\s*m\s*l\s*(,|;))/i;


function _VirtualDom_noScript(tag)
{
	return _VirtualDom_RE_script.test(tag) ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return _VirtualDom_RE_on_formAction.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return _VirtualDom_RE_js.test(value)
		? /**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return _VirtualDom_RE_js_html.test(value)
		? /**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlJson(value)
{
	return (typeof _Json_unwrap(value) === 'string' && _VirtualDom_RE_js_html.test(_Json_unwrap(value)))
		? _Json_wrap(
			/**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		) : value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		aX: func(record.aX),
		aK: record.aK,
		aH: record.aH
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.aX;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.aK;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.aH) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.bC,
		impl.bQ,
		impl.bM,
		function(sendToApp, initialModel) {
			var view = impl.bR;
			/**/
			var domNode = args['node'];
			//*/
			/**_UNUSED/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.bC,
		impl.bQ,
		impl.bM,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.aI && impl.aI(sendToApp)
			var view = impl.bR;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.bp);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.bO) && (_VirtualDom_doc.title = title = doc.bO);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.bE;
	var onUrlRequest = impl.bF;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		aI: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.a3 === next.a3
							&& curr.aU === next.aU
							&& curr.a0.a === next.a0.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		bC: function(flags)
		{
			return A3(impl.bC, flags, _Browser_getUrl(), key);
		},
		bR: impl.bR,
		bQ: impl.bQ,
		bM: impl.bM
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { bA: 'hidden', br: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { bA: 'mozHidden', br: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { bA: 'msHidden', br: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { bA: 'webkitHidden', br: 'webkitvisibilitychange' }
		: { bA: 'hidden', br: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		a9: _Browser_getScene(),
		bg: {
			bi: _Browser_window.pageXOffset,
			bj: _Browser_window.pageYOffset,
			bh: _Browser_doc.documentElement.clientWidth,
			aT: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		bh: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		aT: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			a9: {
				bh: node.scrollWidth,
				aT: node.scrollHeight
			},
			bg: {
				bi: node.scrollLeft,
				bj: node.scrollTop,
				bh: node.clientWidth,
				aT: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			a9: _Browser_getScene(),
			bg: {
				bi: x,
				bj: y,
				bh: _Browser_doc.documentElement.clientWidth,
				aT: _Browser_doc.documentElement.clientHeight
			},
			bv: {
				bi: x + rect.left,
				bj: y + rect.top,
				bh: rect.width,
				aT: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}
var $elm$core$Basics$EQ = 1;
var $elm$core$Basics$GT = 2;
var $elm$core$Basics$LT = 0;
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === -2) {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 1, a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 0, a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 2, a: a};
};
var $elm$core$Basics$False = 1;
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Maybe$Nothing = {$: 1};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 0:
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 1) {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 1:
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 2:
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.e) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.g),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.g);
		} else {
			var treeLen = builder.e * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.h) : builder.h;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.e);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.g) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.g);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{h: nodeList, e: (len / $elm$core$Array$branchFactor) | 0, g: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = 0;
var $elm$core$Result$isOk = function (result) {
	if (!result.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = $elm$core$Basics$identity;
var $elm$url$Url$Http = 0;
var $elm$url$Url$Https = 1;
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {aR: fragment, aU: host, a_: path, a0: port_, a3: protocol, a4: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		0,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		1,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = $elm$core$Basics$identity;
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return 0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0;
		return A2($elm$core$Task$map, tagger, task);
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			A2($elm$core$Task$map, toMessage, task));
	});
var $elm$browser$Browser$element = _Browser_element;
var $author$project$Admin$Ascending = 0;
var $author$project$Admin$ByDate = 1;
var $author$project$Admin$ByStudentName = 0;
var $author$project$Admin$Descending = 1;
var $author$project$Admin$NotAuthenticated = {$: 0};
var $author$project$Admin$SubmissionsPage = {$: 0};
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$Admin$init = function (_v0) {
	return _Utils_Tuple2(
		{n: $author$project$Admin$NotAuthenticated, y: $elm$core$Maybe$Nothing, U: _List_Nil, W: $elm$core$Maybe$Nothing, X: $elm$core$Maybe$Nothing, aj: $elm$core$Maybe$Nothing, Y: $elm$core$Maybe$Nothing, A: $elm$core$Maybe$Nothing, B: $elm$core$Maybe$Nothing, b: $elm$core$Maybe$Nothing, aw: $elm$core$Maybe$Nothing, ax: $elm$core$Maybe$Nothing, al: '', a: false, O: '', P: '', s: '#000000', u: '', m: '', v: '', aa: '', t: $author$project$Admin$SubmissionsPage, ao: 1, ac: 1, ap: '', aq: 0, ad: 0, ar: _List_Nil, J: _List_Nil, K: _List_Nil, k: $elm$core$Maybe$Nothing, ae: '', af: ''},
		$elm$core$Platform$Cmd$none);
};
var $author$project$Admin$BeltResult = function (a) {
	return {$: 39, a: a};
};
var $author$project$Admin$GradeResult = function (a) {
	return {$: 17, a: a};
};
var $author$project$Admin$ReceiveAllStudents = function (a) {
	return {$: 42, a: a};
};
var $author$project$Admin$ReceiveBelts = function (a) {
	return {$: 29, a: a};
};
var $author$project$Admin$ReceiveSubmissions = function (a) {
	return {$: 6, a: a};
};
var $author$project$Admin$ReceivedAuthResult = function (a) {
	return {$: 5, a: a};
};
var $author$project$Admin$ReceivedAuthState = function (a) {
	return {$: 4, a: a};
};
var $author$project$Admin$ReceivedStudentRecord = function (a) {
	return {$: 20, a: a};
};
var $author$project$Admin$StudentCreated = function (a) {
	return {$: 26, a: a};
};
var $author$project$Admin$StudentDeleted = function (a) {
	return {$: 54, a: a};
};
var $author$project$Admin$StudentUpdated = function (a) {
	return {$: 53, a: a};
};
var $author$project$Admin$SubmissionDeleted = function (a) {
	return {$: 58, a: a};
};
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$json$Json$Decode$string = _Json_decodeString;
var $author$project$Admin$beltResult = _Platform_incomingPort('beltResult', $elm$json$Json$Decode$string);
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $elm$json$Json$Decode$bool = _Json_decodeBool;
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $elm$json$Json$Decode$field = _Json_decodeField;
var $author$project$Admin$decodeAuthResult = function (value) {
	var decoder = A3(
		$elm$json$Json$Decode$map2,
		F2(
			function (success, message) {
				return {aX: message, k: success};
			}),
		A2($elm$json$Json$Decode$field, 'success', $elm$json$Json$Decode$bool),
		A2($elm$json$Json$Decode$field, 'message', $elm$json$Json$Decode$string));
	return A2($elm$json$Json$Decode$decodeValue, decoder, value);
};
var $elm$json$Json$Decode$null = _Json_decodeNull;
var $elm$json$Json$Decode$oneOf = _Json_oneOf;
var $elm$json$Json$Decode$nullable = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder)
			]));
};
var $author$project$Admin$User = F3(
	function (uid, email, displayName) {
		return {aB: displayName, aC: email, bP: uid};
	});
var $elm$json$Json$Decode$map3 = _Json_map3;
var $author$project$Admin$userDecoder = A4(
	$elm$json$Json$Decode$map3,
	$author$project$Admin$User,
	A2($elm$json$Json$Decode$field, 'uid', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'email', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'displayName', $elm$json$Json$Decode$string));
var $author$project$Admin$decodeAuthState = function (value) {
	var decoder = A3(
		$elm$json$Json$Decode$map2,
		F2(
			function (user, isSignedIn) {
				return {aV: isSignedIn, bf: user};
			}),
		A2(
			$elm$json$Json$Decode$field,
			'user',
			$elm$json$Json$Decode$nullable($author$project$Admin$userDecoder)),
		A2($elm$json$Json$Decode$field, 'isSignedIn', $elm$json$Json$Decode$bool));
	return A2($elm$json$Json$Decode$decodeValue, decoder, value);
};
var $author$project$Admin$Belt = F5(
	function (id, name, color, order, gameOptions) {
		return {V: color, _: gameOptions, d: id, c: name, Q: order};
	});
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $elm$json$Json$Decode$list = _Json_decodeList;
var $elm$json$Json$Decode$map5 = _Json_map5;
var $author$project$Admin$beltDecoder = A6(
	$elm$json$Json$Decode$map5,
	$author$project$Admin$Belt,
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'name', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'color', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'order', $elm$json$Json$Decode$int),
	A2(
		$elm$json$Json$Decode$field,
		'gameOptions',
		$elm$json$Json$Decode$list($elm$json$Json$Decode$string)));
var $author$project$Admin$decodeBeltsResponse = function (value) {
	return A2(
		$elm$json$Json$Decode$decodeValue,
		$elm$json$Json$Decode$list($author$project$Admin$beltDecoder),
		value);
};
var $author$project$Admin$decodeStudentDeletedResponse = function (value) {
	return A2($elm$json$Json$Decode$decodeValue, $elm$json$Json$Decode$string, value);
};
var $author$project$Admin$Student = F4(
	function (id, name, created, lastActive) {
		return {ai: created, d: id, am: lastActive, c: name};
	});
var $elm$json$Json$Decode$map4 = _Json_map4;
var $author$project$Admin$studentDecoder = A5(
	$elm$json$Json$Decode$map4,
	$author$project$Admin$Student,
	A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'name', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'created', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'lastActive', $elm$json$Json$Decode$string));
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $elm$core$String$cons = _String_cons;
var $elm$core$Char$toUpper = _Char_toUpper;
var $author$project$Admin$capitalizeWord = function (word) {
	var _v0 = $elm$core$String$uncons(word);
	if (!_v0.$) {
		var _v1 = _v0.a;
		var firstChar = _v1.a;
		var rest = _v1.b;
		return A2(
			$elm$core$String$cons,
			$elm$core$Char$toUpper(firstChar),
			rest);
	} else {
		return '';
	}
};
var $author$project$Admin$capitalizeWords = function (str) {
	return A2(
		$elm$core$String$join,
		' ',
		A2(
			$elm$core$List$map,
			$author$project$Admin$capitalizeWord,
			A2($elm$core$String$split, ' ', str)));
};
var $author$project$Admin$Grade = F4(
	function (score, feedback, gradedBy, gradingDate) {
		return {ak: feedback, az: gradedBy, aA: gradingDate, D: score};
	});
var $author$project$Admin$gradeDecoder = A5(
	$elm$json$Json$Decode$map4,
	$author$project$Admin$Grade,
	A2($elm$json$Json$Decode$field, 'score', $elm$json$Json$Decode$int),
	A2($elm$json$Json$Decode$field, 'feedback', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'gradedBy', $elm$json$Json$Decode$string),
	A2($elm$json$Json$Decode$field, 'gradingDate', $elm$json$Json$Decode$string));
var $elm$json$Json$Decode$map6 = _Json_map6;
var $elm$json$Json$Decode$maybe = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder),
				$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
			]));
};
var $elm$core$String$replace = F3(
	function (before, after, string) {
		return A2(
			$elm$core$String$join,
			after,
			A2($elm$core$String$split, before, string));
	});
var $author$project$Admin$submissionDecoder = A2(
	$elm$json$Json$Decode$andThen,
	function (submission) {
		return A2(
			$elm$json$Json$Decode$map,
			function (grade) {
				return _Utils_update(
					submission,
					{i: grade});
			},
			$elm$json$Json$Decode$maybe(
				A2($elm$json$Json$Decode$field, 'grade', $author$project$Admin$gradeDecoder)));
	},
	A2(
		$elm$json$Json$Decode$andThen,
		function (submission) {
			return A2(
				$elm$json$Json$Decode$map,
				function (maybeStudentName) {
					if (!maybeStudentName.$) {
						var studentName = maybeStudentName.a;
						return _Utils_update(
							submission,
							{q: studentName});
					} else {
						return _Utils_update(
							submission,
							{
								q: $author$project$Admin$capitalizeWords(
									A3($elm$core$String$replace, '-', ' ', submission.E))
							});
					}
				},
				$elm$json$Json$Decode$maybe(
					A2($elm$json$Json$Decode$field, 'studentName', $elm$json$Json$Decode$string)));
		},
		A2(
			$elm$json$Json$Decode$andThen,
			function (submission) {
				return A2(
					$elm$json$Json$Decode$map,
					function (maybeStudentId) {
						if (!maybeStudentId.$) {
							var studentId = maybeStudentId.a;
							return _Utils_update(
								submission,
								{E: studentId});
						} else {
							return _Utils_update(
								submission,
								{E: submission.d});
						}
					},
					$elm$json$Json$Decode$maybe(
						A2($elm$json$Json$Decode$field, 'studentId', $elm$json$Json$Decode$string)));
			},
			A7(
				$elm$json$Json$Decode$map6,
				F6(
					function (id, gameBelt, gameName, githubLink, notes, submissionDate) {
						return {z: gameBelt, N: gameName, ay: githubLink, i: $elm$core$Maybe$Nothing, d: id, aF: notes, E: '', q: 'Unknown', F: submissionDate};
					}),
				A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string),
				A2($elm$json$Json$Decode$field, 'beltLevel', $elm$json$Json$Decode$string),
				A2($elm$json$Json$Decode$field, 'gameName', $elm$json$Json$Decode$string),
				A2($elm$json$Json$Decode$field, 'githubLink', $elm$json$Json$Decode$string),
				A2($elm$json$Json$Decode$field, 'notes', $elm$json$Json$Decode$string),
				A2($elm$json$Json$Decode$field, 'submissionDate', $elm$json$Json$Decode$string)))));
var $author$project$Admin$decodeStudentRecordResponse = function (value) {
	var decoder = A3(
		$elm$json$Json$Decode$map2,
		F2(
			function (student, submissions) {
				return {bb: student, K: submissions};
			}),
		A2($elm$json$Json$Decode$field, 'student', $author$project$Admin$studentDecoder),
		A2(
			$elm$json$Json$Decode$field,
			'submissions',
			$elm$json$Json$Decode$list($author$project$Admin$submissionDecoder)));
	return A2($elm$json$Json$Decode$decodeValue, decoder, value);
};
var $author$project$Admin$decodeStudentResponse = function (value) {
	return A2($elm$json$Json$Decode$decodeValue, $author$project$Admin$studentDecoder, value);
};
var $author$project$Admin$decodeStudentsResponse = function (value) {
	return A2(
		$elm$json$Json$Decode$decodeValue,
		$elm$json$Json$Decode$list($author$project$Admin$studentDecoder),
		value);
};
var $author$project$Admin$decodeSubmissionDeletedResponse = function (value) {
	return A2($elm$json$Json$Decode$decodeValue, $elm$json$Json$Decode$string, value);
};
var $author$project$Admin$decodeSubmissionsResponse = function (value) {
	return A2(
		$elm$json$Json$Decode$decodeValue,
		$elm$json$Json$Decode$list($author$project$Admin$submissionDecoder),
		value);
};
var $author$project$Admin$gradeResult = _Platform_incomingPort('gradeResult', $elm$json$Json$Decode$string);
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $author$project$Admin$receiveAllStudents = _Platform_incomingPort('receiveAllStudents', $elm$json$Json$Decode$value);
var $author$project$Admin$receiveAuthResult = _Platform_incomingPort('receiveAuthResult', $elm$json$Json$Decode$value);
var $author$project$Admin$receiveAuthState = _Platform_incomingPort('receiveAuthState', $elm$json$Json$Decode$value);
var $author$project$Admin$receiveBelts = _Platform_incomingPort('receiveBelts', $elm$json$Json$Decode$value);
var $author$project$Admin$receiveStudentRecord = _Platform_incomingPort('receiveStudentRecord', $elm$json$Json$Decode$value);
var $author$project$Admin$receiveSubmissions = _Platform_incomingPort('receiveSubmissions', $elm$json$Json$Decode$value);
var $author$project$Admin$studentCreated = _Platform_incomingPort('studentCreated', $elm$json$Json$Decode$value);
var $author$project$Admin$studentDeleted = _Platform_incomingPort('studentDeleted', $elm$json$Json$Decode$value);
var $author$project$Admin$studentUpdated = _Platform_incomingPort('studentUpdated', $elm$json$Json$Decode$value);
var $author$project$Admin$submissionDeleted = _Platform_incomingPort('submissionDeleted', $elm$json$Json$Decode$value);
var $author$project$Admin$subscriptions = function (_v0) {
	return $elm$core$Platform$Sub$batch(
		_List_fromArray(
			[
				$author$project$Admin$receiveAuthState(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeAuthState, $author$project$Admin$ReceivedAuthState)),
				$author$project$Admin$receiveAuthResult(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeAuthResult, $author$project$Admin$ReceivedAuthResult)),
				$author$project$Admin$receiveSubmissions(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeSubmissionsResponse, $author$project$Admin$ReceiveSubmissions)),
				$author$project$Admin$receiveStudentRecord(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeStudentRecordResponse, $author$project$Admin$ReceivedStudentRecord)),
				$author$project$Admin$studentCreated(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeStudentResponse, $author$project$Admin$StudentCreated)),
				$author$project$Admin$receiveBelts(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeBeltsResponse, $author$project$Admin$ReceiveBelts)),
				$author$project$Admin$receiveAllStudents(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeStudentsResponse, $author$project$Admin$ReceiveAllStudents)),
				$author$project$Admin$studentUpdated(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeStudentResponse, $author$project$Admin$StudentUpdated)),
				$author$project$Admin$studentDeleted(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeStudentDeletedResponse, $author$project$Admin$StudentDeleted)),
				$author$project$Admin$submissionDeleted(
				A2($elm$core$Basics$composeR, $author$project$Admin$decodeSubmissionDeletedResponse, $author$project$Admin$SubmissionDeleted)),
				$author$project$Admin$gradeResult($author$project$Admin$GradeResult),
				$author$project$Admin$beltResult($author$project$Admin$BeltResult)
			]));
};
var $author$project$Admin$Authenticated = function (a) {
	return {$: 2, a: a};
};
var $author$project$Admin$AuthenticatingWith = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Admin$BeltManagementPage = {$: 3};
var $author$project$Admin$CreateStudentPage = {$: 2};
var $author$project$Admin$StudentRecordPage = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $author$project$Admin$createStudent = _Platform_outgoingPort('createStudent', $elm$core$Basics$identity);
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$Admin$deleteBelt = _Platform_outgoingPort('deleteBelt', $elm$json$Json$Encode$string);
var $author$project$Admin$deleteStudent = _Platform_outgoingPort('deleteStudent', $elm$json$Json$Encode$string);
var $author$project$Admin$deleteSubmission = _Platform_outgoingPort('deleteSubmission', $elm$json$Json$Encode$string);
var $elm$json$Json$Encode$int = _Json_wrap;
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(0),
				entries));
	});
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(0),
			pairs));
};
var $author$project$Admin$encodeBelt = function (belt) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$string(belt.d)),
				_Utils_Tuple2(
				'name',
				$elm$json$Json$Encode$string(belt.c)),
				_Utils_Tuple2(
				'color',
				$elm$json$Json$Encode$string(belt.V)),
				_Utils_Tuple2(
				'order',
				$elm$json$Json$Encode$int(belt.Q)),
				_Utils_Tuple2(
				'gameOptions',
				A2($elm$json$Json$Encode$list, $elm$json$Json$Encode$string, belt._))
			]));
};
var $author$project$Admin$encodeCredentials = F2(
	function (email, password) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'email',
					$elm$json$Json$Encode$string(email)),
					_Utils_Tuple2(
					'password',
					$elm$json$Json$Encode$string(password))
				]));
	});
var $author$project$Admin$encodeGrade = function (grade) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'score',
				$elm$json$Json$Encode$int(grade.D)),
				_Utils_Tuple2(
				'feedback',
				$elm$json$Json$Encode$string(grade.ak)),
				_Utils_Tuple2(
				'gradedBy',
				$elm$json$Json$Encode$string(grade.az)),
				_Utils_Tuple2(
				'gradingDate',
				$elm$json$Json$Encode$string(grade.aA))
			]));
};
var $author$project$Admin$encodeNewStudent = function (name) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'name',
				$elm$json$Json$Encode$string(name))
			]));
};
var $author$project$Admin$encodeStudentUpdate = function (student) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$string(student.d)),
				_Utils_Tuple2(
				'name',
				$elm$json$Json$Encode$string(student.c))
			]));
};
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $author$project$Admin$getUserEmail = function (model) {
	var _v0 = model.n;
	if (_v0.$ === 2) {
		var user = _v0.a;
		return user.aC;
	} else {
		return 'unknown@example.com';
	}
};
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $elm$core$Basics$not = _Basics_not;
var $elm$core$List$all = F2(
	function (isOkay, list) {
		return !A2(
			$elm$core$List$any,
			A2($elm$core$Basics$composeL, $elm$core$Basics$not, isOkay),
			list);
	});
var $author$project$Admin$isValidNameFormat = function (name) {
	var parts = A2($elm$core$String$split, '.', name);
	return ($elm$core$List$length(parts) === 2) && A2(
		$elm$core$List$all,
		function (part) {
			return $elm$core$String$length(part) > 0;
		},
		parts);
};
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm$core$Basics$neq = _Utils_notEqual;
var $elm$json$Json$Encode$null = _Json_encodeNull;
var $author$project$Admin$requestAllStudents = _Platform_outgoingPort(
	'requestAllStudents',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Admin$requestBelts = _Platform_outgoingPort(
	'requestBelts',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Admin$requestStudentRecord = _Platform_outgoingPort('requestStudentRecord', $elm$json$Json$Encode$string);
var $author$project$Admin$requestSubmissions = _Platform_outgoingPort(
	'requestSubmissions',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $author$project$Admin$saveBelt = _Platform_outgoingPort('saveBelt', $elm$core$Basics$identity);
var $author$project$Admin$saveGrade = _Platform_outgoingPort('saveGrade', $elm$core$Basics$identity);
var $author$project$Admin$signIn = _Platform_outgoingPort('signIn', $elm$core$Basics$identity);
var $author$project$Admin$signOut = _Platform_outgoingPort(
	'signOut',
	function ($) {
		return $elm$json$Json$Encode$null;
	});
var $elm$core$String$toLower = _String_toLower;
var $elm$core$String$trim = _String_trim;
var $author$project$Admin$updateStudent = _Platform_outgoingPort('updateStudent', $elm$core$Basics$identity);
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$Admin$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 0:
				var email = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{O: email}),
					$elm$core$Platform$Cmd$none);
			case 1:
				var password = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{P: password}),
					$elm$core$Platform$Cmd$none);
			case 2:
				return ($elm$core$String$isEmpty(model.O) || $elm$core$String$isEmpty(model.P)) ? _Utils_Tuple2(
					_Utils_update(
						model,
						{
							y: $elm$core$Maybe$Just('Please enter both email and password')
						}),
					$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
					_Utils_update(
						model,
						{
							n: A2($author$project$Admin$AuthenticatingWith, model.O, model.P),
							y: $elm$core$Maybe$Nothing,
							a: true
						}),
					$author$project$Admin$signIn(
						A2($author$project$Admin$encodeCredentials, model.O, model.P)));
			case 3:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{n: $author$project$Admin$NotAuthenticated, a: true}),
					$author$project$Admin$signOut(0));
			case 4:
				var result = msg.a;
				if (!result.$) {
					var authState = result.a;
					if (authState.aV) {
						var _v2 = authState.bf;
						if (!_v2.$) {
							var user = _v2.a;
							return _Utils_Tuple2(
								_Utils_update(
									model,
									{
										n: $author$project$Admin$Authenticated(user),
										y: $elm$core$Maybe$Nothing,
										a: true
									}),
								$elm$core$Platform$Cmd$batch(
									_List_fromArray(
										[
											$author$project$Admin$requestSubmissions(0),
											$author$project$Admin$requestBelts(0)
										])));
						} else {
							return _Utils_Tuple2(
								_Utils_update(
									model,
									{n: $author$project$Admin$NotAuthenticated, a: false}),
								$elm$core$Platform$Cmd$none);
						}
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{n: $author$project$Admin$NotAuthenticated, a: false}),
							$elm$core$Platform$Cmd$none);
					}
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								n: $author$project$Admin$NotAuthenticated,
								y: $elm$core$Maybe$Just(
									$elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 5:
				var result = msg.a;
				if (!result.$) {
					var authResult = result.a;
					return authResult.k ? _Utils_Tuple2(
						_Utils_update(
							model,
							{a: true}),
						$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
						_Utils_update(
							model,
							{
								n: $author$project$Admin$NotAuthenticated,
								y: $elm$core$Maybe$Just(authResult.aX),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								n: $author$project$Admin$NotAuthenticated,
								y: $elm$core$Maybe$Just(
									$elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 6:
				var result = msg.a;
				if (!result.$) {
					var submissions = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{a: false, K: submissions}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just(
									$elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 7:
				var submission = msg.a;
				var tempScore = A2(
					$elm$core$Maybe$withDefault,
					'',
					A2(
						$elm$core$Maybe$map,
						function (g) {
							return $elm$core$String$fromInt(g.D);
						},
						submission.i));
				var tempFeedback = A2(
					$elm$core$Maybe$withDefault,
					'',
					A2(
						$elm$core$Maybe$map,
						function ($) {
							return $.ak;
						},
						submission.i));
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							Y: $elm$core$Maybe$Just(submission),
							ae: tempFeedback,
							af: tempScore
						}),
					$elm$core$Platform$Cmd$none);
			case 8:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{Y: $elm$core$Maybe$Nothing}),
					$elm$core$Platform$Cmd$none);
			case 9:
				var text = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{al: text}),
					$elm$core$Platform$Cmd$none);
			case 10:
				var belt = msg.a;
				var filterBelt = (belt === 'all') ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(belt);
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{aw: filterBelt}),
					$elm$core$Platform$Cmd$none);
			case 11:
				var status = msg.a;
				var filterGraded = function () {
					switch (status) {
						case 'all':
							return $elm$core$Maybe$Nothing;
						case 'graded':
							return $elm$core$Maybe$Just(true);
						case 'ungraded':
							return $elm$core$Maybe$Just(false);
						default:
							return $elm$core$Maybe$Nothing;
					}
				}();
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{ax: filterGraded}),
					$elm$core$Platform$Cmd$none);
			case 12:
				var sortBy = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{ao: sortBy}),
					$elm$core$Platform$Cmd$none);
			case 13:
				var newDirection = function () {
					var _v6 = model.ac;
					if (!_v6) {
						return 1;
					} else {
						return 0;
					}
				}();
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{ac: newDirection}),
					$elm$core$Platform$Cmd$none);
			case 14:
				var score = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{af: score}),
					$elm$core$Platform$Cmd$none);
			case 15:
				var feedback = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{ae: feedback}),
					$elm$core$Platform$Cmd$none);
			case 16:
				var _v7 = model.Y;
				if (!_v7.$) {
					var submission = _v7.a;
					var scoreResult = $elm$core$String$toInt(model.af);
					if (!scoreResult.$) {
						var score = scoreResult.a;
						if ((score < 0) || (score > 100)) {
							return _Utils_Tuple2(
								_Utils_update(
									model,
									{
										b: $elm$core$Maybe$Just('Score must be between 0 and 100')
									}),
								$elm$core$Platform$Cmd$none);
						} else {
							var grade = {
								ak: model.ae,
								az: $author$project$Admin$getUserEmail(model),
								aA: '2025-03-03',
								D: score
							};
							var gradeData = $elm$json$Json$Encode$object(
								_List_fromArray(
									[
										_Utils_Tuple2(
										'submissionId',
										$elm$json$Json$Encode$string(submission.d)),
										_Utils_Tuple2(
										'grade',
										$author$project$Admin$encodeGrade(grade))
									]));
							return _Utils_Tuple2(
								_Utils_update(
									model,
									{b: $elm$core$Maybe$Nothing, a: true, k: $elm$core$Maybe$Nothing}),
								$author$project$Admin$saveGrade(gradeData));
						}
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{
									b: $elm$core$Maybe$Just('Please enter a valid score (0-100)')
								}),
							$elm$core$Platform$Cmd$none);
					}
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 17:
				var result = msg.a;
				return A2($elm$core$String$startsWith, 'Error:', result) ? _Utils_Tuple2(
					_Utils_update(
						model,
						{
							b: $elm$core$Maybe$Just(result),
							a: false,
							k: $elm$core$Maybe$Nothing
						}),
					$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
					_Utils_update(
						model,
						{
							b: $elm$core$Maybe$Nothing,
							a: false,
							k: $elm$core$Maybe$Just('Grade saved successfully')
						}),
					$author$project$Admin$requestSubmissions(0));
			case 18:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{a: true}),
					$author$project$Admin$requestSubmissions(0));
			case 19:
				var studentId = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{a: true, t: $author$project$Admin$SubmissionsPage}),
					$author$project$Admin$requestStudentRecord(studentId));
			case 20:
				var result = msg.a;
				if (!result.$) {
					var submissions = result.a.K;
					var student = result.a.bb;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								aj: $elm$core$Maybe$Just(student),
								a: false,
								t: A2($author$project$Admin$StudentRecordPage, student, submissions),
								ar: submissions
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just(
									'Failed to load student record: ' + $elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 21:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{aj: $elm$core$Maybe$Nothing, t: $author$project$Admin$SubmissionsPage, ar: _List_Nil}),
					$elm$core$Platform$Cmd$none);
			case 23:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{t: $author$project$Admin$SubmissionsPage}),
					$elm$core$Platform$Cmd$none);
			case 24:
				var name = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{aa: name}),
					$elm$core$Platform$Cmd$none);
			case 25:
				var trimmedName = $elm$core$String$trim(model.aa);
				return $elm$core$String$isEmpty(trimmedName) ? _Utils_Tuple2(
					_Utils_update(
						model,
						{
							b: $elm$core$Maybe$Just('Please enter a student name')
						}),
					$elm$core$Platform$Cmd$none) : ((!$author$project$Admin$isValidNameFormat(trimmedName)) ? _Utils_Tuple2(
					_Utils_update(
						model,
						{
							b: $elm$core$Maybe$Just('Please enter the name in the format firstname.lastname (e.g., tyler.smith)')
						}),
					$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
					_Utils_update(
						model,
						{b: $elm$core$Maybe$Nothing, a: true}),
					$author$project$Admin$createStudent(
						$author$project$Admin$encodeNewStudent(trimmedName))));
			case 26:
				var result = msg.a;
				if (!result.$) {
					var student = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								aj: $elm$core$Maybe$Just(student),
								a: false,
								t: A2($author$project$Admin$StudentRecordPage, student, _List_Nil),
								ar: _List_Nil,
								k: $elm$core$Maybe$Just('Student record for ' + (student.c + ' created successfully'))
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just(
									'Error creating student: ' + $elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 27:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{A: $elm$core$Maybe$Nothing, b: $elm$core$Maybe$Nothing, s: '#000000', u: '', m: '', v: '', t: $author$project$Admin$BeltManagementPage, k: $elm$core$Maybe$Nothing}),
					$author$project$Admin$requestBelts(0));
			case 28:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{t: $author$project$Admin$SubmissionsPage}),
					$elm$core$Platform$Cmd$none);
			case 29:
				var result = msg.a;
				if (!result.$) {
					var belts = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{U: belts, a: false}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just(
									$elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 30:
				var name = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{m: name}),
					$elm$core$Platform$Cmd$none);
			case 31:
				var color = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{s: color}),
					$elm$core$Platform$Cmd$none);
			case 32:
				var order = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{v: order}),
					$elm$core$Platform$Cmd$none);
			case 33:
				var options = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{u: options}),
					$elm$core$Platform$Cmd$none);
			case 34:
				if ($elm$core$String$trim(model.m) === '') {
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just('Please enter a belt name')
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					var orderResult = $elm$core$String$toInt(model.v);
					if (!orderResult.$) {
						var order = orderResult.a;
						var gameOptions = A2(
							$elm$core$List$filter,
							A2($elm$core$Basics$composeL, $elm$core$Basics$not, $elm$core$String$isEmpty),
							A2(
								$elm$core$List$map,
								$elm$core$String$trim,
								A2($elm$core$String$split, ',', model.u)));
						var beltId = A3(
							$elm$core$String$replace,
							' ',
							'-',
							$elm$core$String$toLower(model.m));
						var newBelt = {V: model.s, _: gameOptions, d: beltId, c: model.m, Q: order};
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{b: $elm$core$Maybe$Nothing, a: true}),
							$author$project$Admin$saveBelt(
								$author$project$Admin$encodeBelt(newBelt)));
					} else {
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{
									b: $elm$core$Maybe$Just('Please enter a valid order number')
								}),
							$elm$core$Platform$Cmd$none);
					}
				}
			case 35:
				var belt = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							A: $elm$core$Maybe$Just(belt),
							s: belt.V,
							u: A2($elm$core$String$join, ', ', belt._),
							m: belt.c,
							v: $elm$core$String$fromInt(belt.Q)
						}),
					$elm$core$Platform$Cmd$none);
			case 36:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{A: $elm$core$Maybe$Nothing, s: '#000000', u: '', m: '', v: ''}),
					$elm$core$Platform$Cmd$none);
			case 37:
				var _v13 = model.A;
				if (!_v13.$) {
					var belt = _v13.a;
					if ($elm$core$String$trim(model.m) === '') {
						return _Utils_Tuple2(
							_Utils_update(
								model,
								{
									b: $elm$core$Maybe$Just('Please enter a belt name')
								}),
							$elm$core$Platform$Cmd$none);
					} else {
						var orderResult = $elm$core$String$toInt(model.v);
						if (!orderResult.$) {
							var order = orderResult.a;
							var gameOptions = A2(
								$elm$core$List$filter,
								A2($elm$core$Basics$composeL, $elm$core$Basics$not, $elm$core$String$isEmpty),
								A2(
									$elm$core$List$map,
									$elm$core$String$trim,
									A2($elm$core$String$split, ',', model.u)));
							var updatedBelt = {V: model.s, _: gameOptions, d: belt.d, c: model.m, Q: order};
							return _Utils_Tuple2(
								_Utils_update(
									model,
									{b: $elm$core$Maybe$Nothing, a: true}),
								$author$project$Admin$saveBelt(
									$author$project$Admin$encodeBelt(updatedBelt)));
						} else {
							return _Utils_Tuple2(
								_Utils_update(
									model,
									{
										b: $elm$core$Maybe$Just('Please enter a valid order number')
									}),
								$elm$core$Platform$Cmd$none);
						}
					}
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 38:
				var beltId = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{a: true}),
					$author$project$Admin$deleteBelt(beltId));
			case 39:
				var result = msg.a;
				return A2($elm$core$String$startsWith, 'Error:', result) ? _Utils_Tuple2(
					_Utils_update(
						model,
						{
							b: $elm$core$Maybe$Just(result),
							a: false,
							k: $elm$core$Maybe$Nothing
						}),
					$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
					_Utils_update(
						model,
						{
							A: $elm$core$Maybe$Nothing,
							b: $elm$core$Maybe$Nothing,
							a: false,
							s: '#000000',
							u: '',
							m: '',
							v: '',
							k: $elm$core$Maybe$Just(result)
						}),
					$author$project$Admin$requestBelts(0));
			case 40:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{a: true}),
					$author$project$Admin$requestBelts(0));
			case 22:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{aa: '', t: $author$project$Admin$CreateStudentPage}),
					$author$project$Admin$requestAllStudents(0));
			case 41:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{a: true}),
					$author$project$Admin$requestAllStudents(0));
			case 42:
				var result = msg.a;
				if (!result.$) {
					var students = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{a: false, J: students}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just(
									$elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 43:
				var text = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{ap: text}),
					$elm$core$Platform$Cmd$none);
			case 44:
				var sortBy = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{aq: sortBy}),
					$elm$core$Platform$Cmd$none);
			case 45:
				var newDirection = function () {
					var _v16 = model.ad;
					if (!_v16) {
						return 1;
					} else {
						return 0;
					}
				}();
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{ad: newDirection}),
					$elm$core$Platform$Cmd$none);
			case 46:
				var student = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							B: $elm$core$Maybe$Just(student)
						}),
					$elm$core$Platform$Cmd$none);
			case 48:
				var name = msg.a;
				var _v17 = model.B;
				if (!_v17.$) {
					var student = _v17.a;
					var updatedStudent = _Utils_update(
						student,
						{c: name});
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								B: $elm$core$Maybe$Just(updatedStudent)
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 49:
				var _v18 = model.B;
				if (!_v18.$) {
					var student = _v18.a;
					return ($elm$core$String$trim(student.c) === '') ? _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just('Please enter a student name')
							}),
						$elm$core$Platform$Cmd$none) : ((!$author$project$Admin$isValidNameFormat(student.c)) ? _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just('Please enter the name in the format firstname.lastname')
							}),
						$elm$core$Platform$Cmd$none) : _Utils_Tuple2(
						_Utils_update(
							model,
							{B: $elm$core$Maybe$Nothing, b: $elm$core$Maybe$Nothing, a: true}),
						$author$project$Admin$updateStudent(
							$author$project$Admin$encodeStudentUpdate(student))));
				} else {
					return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
				}
			case 50:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{B: $elm$core$Maybe$Nothing, b: $elm$core$Maybe$Nothing}),
					$elm$core$Platform$Cmd$none);
			case 47:
				var student = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							W: $elm$core$Maybe$Just(student)
						}),
					$elm$core$Platform$Cmd$none);
			case 51:
				var student = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{W: $elm$core$Maybe$Nothing, a: true}),
					$author$project$Admin$deleteStudent(student.d));
			case 52:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{W: $elm$core$Maybe$Nothing}),
					$elm$core$Platform$Cmd$none);
			case 53:
				var result = msg.a;
				if (!result.$) {
					var student = result.a;
					var updatedStudents = A2(
						$elm$core$List$map,
						function (s) {
							return _Utils_eq(s.d, student.d) ? student : s;
						},
						model.J);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								a: false,
								J: updatedStudents,
								k: $elm$core$Maybe$Just('Student ' + (student.c + ' updated successfully'))
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just(
									'Error updating student: ' + $elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 54:
				var result = msg.a;
				if (!result.$) {
					var studentId = result.a;
					var updatedStudents = A2(
						$elm$core$List$filter,
						function (s) {
							return !_Utils_eq(s.d, studentId);
						},
						model.J);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								a: false,
								J: updatedStudents,
								k: $elm$core$Maybe$Just('Student deleted successfully')
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just(
									'Error deleting student: ' + $elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
			case 55:
				var submission = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							X: $elm$core$Maybe$Just(submission)
						}),
					$elm$core$Platform$Cmd$none);
			case 56:
				var submission = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{X: $elm$core$Maybe$Nothing, a: true}),
					$author$project$Admin$deleteSubmission(submission.d));
			case 57:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{X: $elm$core$Maybe$Nothing}),
					$elm$core$Platform$Cmd$none);
			default:
				var result = msg.a;
				if (!result.$) {
					var submissionId = result.a;
					var updatedSubmissions = A2(
						$elm$core$List$filter,
						function (s) {
							return !_Utils_eq(s.d, submissionId);
						},
						model.K);
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								a: false,
								K: updatedSubmissions,
								k: $elm$core$Maybe$Just('Submission deleted successfully')
							}),
						$elm$core$Platform$Cmd$none);
				} else {
					var error = result.a;
					return _Utils_Tuple2(
						_Utils_update(
							model,
							{
								b: $elm$core$Maybe$Just(
									'Error deleting submission: ' + $elm$json$Json$Decode$errorToString(error)),
								a: false
							}),
						$elm$core$Platform$Cmd$none);
				}
		}
	});
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$div = _VirtualDom_node('div');
var $elm$html$Html$h1 = _VirtualDom_node('h1');
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $author$project$Admin$PerformSignOut = {$: 3};
var $elm$html$Html$button = _VirtualDom_node('button');
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 0, a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$html$Html$p = _VirtualDom_node('p');
var $elm$core$String$toUpper = _String_toUpper;
var $author$project$Admin$CancelDeleteSubmission = {$: 57};
var $author$project$Admin$ConfirmDeleteSubmission = function (a) {
	return {$: 56, a: a};
};
var $elm$core$List$drop = F2(
	function (n, list) {
		drop:
		while (true) {
			if (n <= 0) {
				return list;
			} else {
				if (!list.b) {
					return list;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs;
					n = $temp$n;
					list = $temp$list;
					continue drop;
				}
			}
		}
	});
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Admin$formatDisplayName = function (name) {
	var parts = A2($elm$core$String$split, '.', name);
	var lastName = A2(
		$elm$core$Maybe$withDefault,
		'',
		$elm$core$List$head(
			A2($elm$core$List$drop, 1, parts)));
	var firstName = A2(
		$elm$core$Maybe$withDefault,
		'',
		$elm$core$List$head(parts));
	var capitalizedLast = _Utils_ap(
		$elm$core$String$toUpper(
			A2($elm$core$String$left, 1, lastName)),
		A2($elm$core$String$dropLeft, 1, lastName));
	var capitalizedFirst = _Utils_ap(
		$elm$core$String$toUpper(
			A2($elm$core$String$left, 1, firstName)),
		A2($elm$core$String$dropLeft, 1, firstName));
	return capitalizedFirst + (' ' + capitalizedLast);
};
var $elm$html$Html$h2 = _VirtualDom_node('h2');
var $author$project$Admin$viewConfirmDeleteSubmissionModal = function (submission) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('px-6 py-4 bg-red-50 border-b border-gray-200')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$h2,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-lg font-medium text-red-700')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Confirm Delete')
									]))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('p-6')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$p,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('mb-6 text-gray-700')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'Are you sure you want to delete the submission for ' + ($author$project$Admin$formatDisplayName(submission.q) + ('\'s ' + (submission.N + '? This action cannot be undone.'))))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex justify-end space-x-3')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick($author$project$Admin$CancelDeleteSubmission),
												$elm$html$Html$Attributes$class('px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Cancel')
											])),
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick(
												$author$project$Admin$ConfirmDeleteSubmission(submission)),
												$elm$html$Html$Attributes$class('px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Delete Submission')
											]))
									]))
							]))
					]))
			]));
};
var $author$project$Admin$AddNewBelt = {$: 34};
var $author$project$Admin$CancelEditBelt = {$: 36};
var $author$project$Admin$CloseBeltManagement = {$: 28};
var $author$project$Admin$RefreshBelts = {$: 40};
var $author$project$Admin$UpdateBelt = {$: 37};
var $author$project$Admin$UpdateNewBeltColor = function (a) {
	return {$: 31, a: a};
};
var $author$project$Admin$UpdateNewBeltGameOptions = function (a) {
	return {$: 33, a: a};
};
var $author$project$Admin$UpdateNewBeltName = function (a) {
	return {$: 30, a: a};
};
var $author$project$Admin$UpdateNewBeltOrder = function (a) {
	return {$: 32, a: a};
};
var $elm$html$Html$Attributes$for = $elm$html$Html$Attributes$stringProperty('htmlFor');
var $elm$html$Html$h3 = _VirtualDom_node('h3');
var $elm$html$Html$Attributes$id = $elm$html$Html$Attributes$stringProperty('id');
var $elm$html$Html$input = _VirtualDom_node('input');
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $elm$html$Html$label = _VirtualDom_node('label');
var $elm$html$Html$Events$alwaysStop = function (x) {
	return _Utils_Tuple2(x, true);
};
var $elm$virtual_dom$VirtualDom$MayStopPropagation = function (a) {
	return {$: 1, a: a};
};
var $elm$html$Html$Events$stopPropagationOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayStopPropagation(decoder));
	});
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $elm$html$Html$Events$targetValue = A2(
	$elm$json$Json$Decode$at,
	_List_fromArray(
		['target', 'value']),
	$elm$json$Json$Decode$string);
var $elm$html$Html$Events$onInput = function (tagger) {
	return A2(
		$elm$html$Html$Events$stopPropagationOn,
		'input',
		A2(
			$elm$json$Json$Decode$map,
			$elm$html$Html$Events$alwaysStop,
			A2($elm$json$Json$Decode$map, tagger, $elm$html$Html$Events$targetValue)));
};
var $elm$html$Html$Attributes$placeholder = $elm$html$Html$Attributes$stringProperty('placeholder');
var $elm$html$Html$Attributes$rows = function (n) {
	return A2(
		_VirtualDom_attribute,
		'rows',
		$elm$core$String$fromInt(n));
};
var $elm$core$List$sortBy = _List_sortBy;
var $elm$html$Html$span = _VirtualDom_node('span');
var $elm$html$Html$textarea = _VirtualDom_node('textarea');
var $elm$html$Html$Attributes$type_ = $elm$html$Html$Attributes$stringProperty('type');
var $elm$html$Html$ul = _VirtualDom_node('ul');
var $elm$html$Html$Attributes$value = $elm$html$Html$Attributes$stringProperty('value');
var $author$project$Admin$DeleteBelt = function (a) {
	return {$: 38, a: a};
};
var $author$project$Admin$EditBelt = function (a) {
	return {$: 35, a: a};
};
var $elm$html$Html$li = _VirtualDom_node('li');
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $elm$core$List$takeReverse = F3(
	function (n, list, kept) {
		takeReverse:
		while (true) {
			if (n <= 0) {
				return kept;
			} else {
				if (!list.b) {
					return kept;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs,
						$temp$kept = A2($elm$core$List$cons, x, kept);
					n = $temp$n;
					list = $temp$list;
					kept = $temp$kept;
					continue takeReverse;
				}
			}
		}
	});
var $elm$core$List$takeTailRec = F2(
	function (n, list) {
		return $elm$core$List$reverse(
			A3($elm$core$List$takeReverse, n, list, _List_Nil));
	});
var $elm$core$List$takeFast = F3(
	function (ctr, n, list) {
		if (n <= 0) {
			return _List_Nil;
		} else {
			var _v0 = _Utils_Tuple2(n, list);
			_v0$1:
			while (true) {
				_v0$5:
				while (true) {
					if (!_v0.b.b) {
						return list;
					} else {
						if (_v0.b.b.b) {
							switch (_v0.a) {
								case 1:
									break _v0$1;
								case 2:
									var _v2 = _v0.b;
									var x = _v2.a;
									var _v3 = _v2.b;
									var y = _v3.a;
									return _List_fromArray(
										[x, y]);
								case 3:
									if (_v0.b.b.b.b) {
										var _v4 = _v0.b;
										var x = _v4.a;
										var _v5 = _v4.b;
										var y = _v5.a;
										var _v6 = _v5.b;
										var z = _v6.a;
										return _List_fromArray(
											[x, y, z]);
									} else {
										break _v0$5;
									}
								default:
									if (_v0.b.b.b.b && _v0.b.b.b.b.b) {
										var _v7 = _v0.b;
										var x = _v7.a;
										var _v8 = _v7.b;
										var y = _v8.a;
										var _v9 = _v8.b;
										var z = _v9.a;
										var _v10 = _v9.b;
										var w = _v10.a;
										var tl = _v10.b;
										return (ctr > 1000) ? A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A2($elm$core$List$takeTailRec, n - 4, tl))))) : A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A3($elm$core$List$takeFast, ctr + 1, n - 4, tl)))));
									} else {
										break _v0$5;
									}
							}
						} else {
							if (_v0.a === 1) {
								break _v0$1;
							} else {
								break _v0$5;
							}
						}
					}
				}
				return list;
			}
			var _v1 = _v0.b;
			var x = _v1.a;
			return _List_fromArray(
				[x]);
		}
	});
var $elm$core$List$take = F2(
	function (n, list) {
		return A3($elm$core$List$takeFast, 0, n, list);
	});
var $author$project$Admin$truncateGamesList = function (games) {
	var totalGames = $elm$core$List$length(games);
	var maxGamesToShow = 3;
	var displayGames = (_Utils_cmp(totalGames, maxGamesToShow) < 1) ? games : _Utils_ap(
		A2($elm$core$List$take, maxGamesToShow, games),
		_List_fromArray(
			[
				'...' + ($elm$core$String$fromInt(totalGames - maxGamesToShow) + ' more')
			]));
	return A2($elm$core$String$join, ', ', displayGames);
};
var $author$project$Admin$viewBeltRow = F2(
	function (model, belt) {
		return A2(
			$elm$html$Html$li,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('py-4 px-6 flex items-center justify-between hover:bg-gray-50')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('flex items-center space-x-4')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('w-8 h-8 rounded-full border border-gray-300 flex-shrink-0'),
									A2($elm$html$Html$Attributes$style, 'background-color', belt.V)
								]),
							_List_Nil),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('flex-1 min-w-0')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('flex items-center')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$p,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('text-sm font-medium text-gray-900 truncate')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(belt.c)
												])),
											A2(
											$elm$html$Html$span,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('ml-2 text-xs text-gray-500')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(
													'Order: ' + $elm$core$String$fromInt(belt.Q))
												]))
										])),
									A2(
									$elm$html$Html$p,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('text-xs text-gray-500 truncate')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											'Games: ' + $author$project$Admin$truncateGamesList(belt._))
										]))
								]))
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('flex space-x-2 ml-2 flex-shrink-0')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$button,
							_List_fromArray(
								[
									$elm$html$Html$Events$onClick(
									$author$project$Admin$EditBelt(belt)),
									$elm$html$Html$Attributes$class('px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition')
								]),
							_List_fromArray(
								[
									$elm$html$Html$text('Edit')
								])),
							A2(
							$elm$html$Html$button,
							_List_fromArray(
								[
									$elm$html$Html$Events$onClick(
									$author$project$Admin$DeleteBelt(belt.d)),
									$elm$html$Html$Attributes$class('px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition')
								]),
							_List_fromArray(
								[
									$elm$html$Html$text('Delete')
								]))
						]))
				]));
	});
var $author$project$Admin$viewBeltManagementPage = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('space-y-6')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('bg-white shadow rounded-lg p-6')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex justify-between items-center')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$h2,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-xl font-medium text-gray-900')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Belt Management')
									])),
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$Admin$CloseBeltManagement),
										$elm$html$Html$Attributes$class('text-gray-500 hover:text-gray-700 flex items-center')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$span,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('mr-1')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('←')
											])),
										$elm$html$Html$text('Back to Submissions')
									]))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('mt-6')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('bg-white overflow-hidden shadow-sm rounded-lg border border-gray-200')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('px-6 py-4 bg-gray-50 border-b border-gray-200')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$h3,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text(
														function () {
															var _v0 = model.A;
															if (!_v0.$) {
																var belt = _v0.a;
																return 'Edit Belt: ' + belt.c;
															} else {
																return 'Add New Belt';
															}
														}())
													]))
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('p-6')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('grid grid-cols-1 md:grid-cols-2 gap-4')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$div,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('space-y-2')
															]),
														_List_fromArray(
															[
																A2(
																$elm$html$Html$label,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$for('beltName'),
																		$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																	]),
																_List_fromArray(
																	[
																		$elm$html$Html$text('Belt Name:')
																	])),
																A2(
																$elm$html$Html$input,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$type_('text'),
																		$elm$html$Html$Attributes$id('beltName'),
																		$elm$html$Html$Attributes$value(model.m),
																		$elm$html$Html$Events$onInput($author$project$Admin$UpdateNewBeltName),
																		$elm$html$Html$Attributes$placeholder('e.g. White Belt, Yellow Belt'),
																		$elm$html$Html$Attributes$class('mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
																	]),
																_List_Nil)
															])),
														A2(
														$elm$html$Html$div,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('space-y-2')
															]),
														_List_fromArray(
															[
																A2(
																$elm$html$Html$label,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$for('beltColor'),
																		$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																	]),
																_List_fromArray(
																	[
																		$elm$html$Html$text('Belt Color:')
																	])),
																A2(
																$elm$html$Html$div,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$class('flex items-center space-x-2')
																	]),
																_List_fromArray(
																	[
																		A2(
																		$elm$html$Html$input,
																		_List_fromArray(
																			[
																				$elm$html$Html$Attributes$type_('color'),
																				$elm$html$Html$Attributes$id('beltColor'),
																				$elm$html$Html$Attributes$value(model.s),
																				$elm$html$Html$Events$onInput($author$project$Admin$UpdateNewBeltColor),
																				$elm$html$Html$Attributes$class('h-8 w-8 border border-gray-300 rounded')
																			]),
																		_List_Nil),
																		A2(
																		$elm$html$Html$input,
																		_List_fromArray(
																			[
																				$elm$html$Html$Attributes$type_('text'),
																				$elm$html$Html$Attributes$value(model.s),
																				$elm$html$Html$Events$onInput($author$project$Admin$UpdateNewBeltColor),
																				$elm$html$Html$Attributes$placeholder('#000000'),
																				$elm$html$Html$Attributes$class('flex-1 mt-1 border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
																			]),
																		_List_Nil)
																	]))
															])),
														A2(
														$elm$html$Html$div,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('space-y-2')
															]),
														_List_fromArray(
															[
																A2(
																$elm$html$Html$label,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$for('beltOrder'),
																		$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																	]),
																_List_fromArray(
																	[
																		$elm$html$Html$text('Display Order:')
																	])),
																A2(
																$elm$html$Html$input,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$type_('number'),
																		$elm$html$Html$Attributes$id('beltOrder'),
																		$elm$html$Html$Attributes$value(model.v),
																		$elm$html$Html$Events$onInput($author$project$Admin$UpdateNewBeltOrder),
																		$elm$html$Html$Attributes$placeholder('1, 2, 3, etc.'),
																		$elm$html$Html$Attributes$class('mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
																	]),
																_List_Nil)
															])),
														A2(
														$elm$html$Html$div,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('space-y-2')
															]),
														_List_fromArray(
															[
																A2(
																$elm$html$Html$label,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$for('gameOptions'),
																		$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																	]),
																_List_fromArray(
																	[
																		$elm$html$Html$text('Game Options (comma separated):')
																	])),
																A2(
																$elm$html$Html$textarea,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$id('gameOptions'),
																		$elm$html$Html$Attributes$value(model.u),
																		$elm$html$Html$Events$onInput($author$project$Admin$UpdateNewBeltGameOptions),
																		$elm$html$Html$Attributes$placeholder('Game 1, Game 2, Game 3'),
																		$elm$html$Html$Attributes$rows(3),
																		$elm$html$Html$Attributes$class('mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
																	]),
																_List_Nil)
															]))
													])),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('mt-6 flex space-x-3')
													]),
												_List_fromArray(
													[
														function () {
														var _v1 = model.A;
														if (!_v1.$) {
															var belt = _v1.a;
															return A2(
																$elm$html$Html$div,
																_List_fromArray(
																	[
																		$elm$html$Html$Attributes$class('flex space-x-3 w-full')
																	]),
																_List_fromArray(
																	[
																		A2(
																		$elm$html$Html$button,
																		_List_fromArray(
																			[
																				$elm$html$Html$Events$onClick($author$project$Admin$UpdateBelt),
																				$elm$html$Html$Attributes$class('flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500')
																			]),
																		_List_fromArray(
																			[
																				$elm$html$Html$text('Update Belt')
																			])),
																		A2(
																		$elm$html$Html$button,
																		_List_fromArray(
																			[
																				$elm$html$Html$Events$onClick($author$project$Admin$CancelEditBelt),
																				$elm$html$Html$Attributes$class('py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500')
																			]),
																		_List_fromArray(
																			[
																				$elm$html$Html$text('Cancel')
																			]))
																	]));
														} else {
															return A2(
																$elm$html$Html$button,
																_List_fromArray(
																	[
																		$elm$html$Html$Events$onClick($author$project$Admin$AddNewBelt),
																		$elm$html$Html$Attributes$class('w-full py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500')
																	]),
																_List_fromArray(
																	[
																		$elm$html$Html$text('Add Belt')
																	]));
														}
													}()
													]))
											]))
									]))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('mt-8')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex justify-between items-center mb-4')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$h3,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Current Belts')
											])),
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick($author$project$Admin$RefreshBelts),
												$elm$html$Html$Attributes$class('py-1 px-3 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Refresh')
											]))
									])),
								$elm$core$List$isEmpty(model.U) ? A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-center py-12 bg-gray-50 rounded-lg border border-gray-200')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$p,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('text-gray-500')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('No belts configured yet. Add your first belt above.')
											]))
									])) : A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('bg-white shadow overflow-hidden sm:rounded-lg border border-gray-200')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$ul,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('divide-y divide-gray-200')
											]),
										A2(
											$elm$core$List$map,
											$author$project$Admin$viewBeltRow(model),
											A2(
												$elm$core$List$sortBy,
												function ($) {
													return $.Q;
												},
												model.U)))
									]))
							]))
					]))
			]));
};
var $author$project$Admin$ByStudentCreated = 1;
var $author$project$Admin$ByStudentLastActive = 2;
var $author$project$Admin$CloseCreateStudentForm = {$: 23};
var $author$project$Admin$CreateNewStudent = {$: 25};
var $author$project$Admin$RequestAllStudents = {$: 41};
var $author$project$Admin$ToggleStudentSortDirection = {$: 45};
var $author$project$Admin$UpdateNewStudentName = function (a) {
	return {$: 24, a: a};
};
var $author$project$Admin$UpdateStudentFilterText = function (a) {
	return {$: 43, a: a};
};
var $author$project$Admin$UpdateStudentSortBy = function (a) {
	return {$: 44, a: a};
};
var $author$project$Admin$filterStudentByText = F2(
	function (filterText, student) {
		if ($elm$core$String$isEmpty(filterText)) {
			return true;
		} else {
			var lowercaseFilter = $elm$core$String$toLower(filterText);
			var containsFilter = function (text) {
				return A2(
					$elm$core$String$contains,
					lowercaseFilter,
					$elm$core$String$toLower(text));
			};
			return containsFilter(student.c) || containsFilter(student.d);
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$List$sortWith = _List_sortWith;
var $author$project$Admin$sortStudents = F3(
	function (sortBy, direction, students) {
		var sortFunction = function () {
			switch (sortBy) {
				case 0:
					return F2(
						function (a, b) {
							return A2($elm$core$Basics$compare, a.c, b.c);
						});
				case 1:
					return F2(
						function (a, b) {
							return A2($elm$core$Basics$compare, a.ai, b.ai);
						});
				default:
					return F2(
						function (a, b) {
							return A2($elm$core$Basics$compare, a.am, b.am);
						});
			}
		}();
		var sortedList = A2($elm$core$List$sortWith, sortFunction, students);
		if (!direction) {
			return sortedList;
		} else {
			return $elm$core$List$reverse(sortedList);
		}
	});
var $author$project$Admin$applyStudentFilters = function (model) {
	return A3(
		$author$project$Admin$sortStudents,
		model.aq,
		model.ad,
		A2(
			$elm$core$List$filter,
			$author$project$Admin$filterStudentByText(model.ap),
			model.J));
};
var $author$project$Admin$getStudentSortButtonClass = F2(
	function (model, sortType) {
		var baseClass = 'px-3 py-1 rounded text-sm';
		return _Utils_eq(model.aq, sortType) ? (baseClass + ' bg-blue-100 text-blue-800 font-medium') : (baseClass + ' text-gray-600 hover:bg-gray-100');
	});
var $elm$html$Html$table = _VirtualDom_node('table');
var $elm$html$Html$tbody = _VirtualDom_node('tbody');
var $elm$html$Html$th = _VirtualDom_node('th');
var $elm$html$Html$thead = _VirtualDom_node('thead');
var $elm$html$Html$tr = _VirtualDom_node('tr');
var $author$project$Admin$CancelDeleteStudent = {$: 52};
var $author$project$Admin$ConfirmDeleteStudent = function (a) {
	return {$: 51, a: a};
};
var $author$project$Admin$viewConfirmDeleteModal = function (student) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('px-6 py-4 bg-red-50 border-b border-gray-200')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$h2,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-lg font-medium text-red-700')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Confirm Delete')
									]))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('p-6')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$p,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('mb-4 text-gray-700')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'Are you sure you want to delete the student record for ' + ($author$project$Admin$formatDisplayName(student.c) + '?'))
									])),
								A2(
								$elm$html$Html$p,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('mb-6 text-red-600 font-medium')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('This will permanently delete the student AND all their game submissions. This action cannot be undone.')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex justify-end space-x-3')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick($author$project$Admin$CancelDeleteStudent),
												$elm$html$Html$Attributes$class('px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Cancel')
											])),
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick(
												$author$project$Admin$ConfirmDeleteStudent(student)),
												$elm$html$Html$Attributes$class('px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Delete Student & Submissions')
											]))
									]))
							]))
					]))
			]));
};
var $author$project$Admin$CancelStudentEdit = {$: 50};
var $author$project$Admin$SaveStudentEdit = {$: 49};
var $author$project$Admin$UpdateEditingStudentName = function (a) {
	return {$: 48, a: a};
};
var $author$project$Admin$viewEditStudentModal = F2(
	function (model, student) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('bg-white rounded-lg overflow-hidden shadow-xl max-w-md w-full m-4')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('px-6 py-4 bg-gray-50 border-b border-gray-200')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$h2,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text('Edit Student')
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('p-6')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('space-y-4')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_Nil,
											_List_fromArray(
												[
													A2(
													$elm$html$Html$label,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$for('editStudentName'),
															$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
														]),
													_List_fromArray(
														[
															$elm$html$Html$text('Student Name:')
														])),
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('text'),
															$elm$html$Html$Attributes$id('editStudentName'),
															$elm$html$Html$Attributes$value(student.c),
															$elm$html$Html$Events$onInput($author$project$Admin$UpdateEditingStudentName),
															$elm$html$Html$Attributes$placeholder('firstname.lastname'),
															$elm$html$Html$Attributes$class('mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
														]),
													_List_Nil),
													A2(
													$elm$html$Html$p,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$class('text-sm text-gray-500 mt-1')
														]),
													_List_fromArray(
														[
															$elm$html$Html$text('Name must be in format: firstname.lastname')
														]))
												])),
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('pt-2 flex justify-end space-x-3')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$button,
													_List_fromArray(
														[
															$elm$html$Html$Events$onClick($author$project$Admin$CancelStudentEdit),
															$elm$html$Html$Attributes$class('px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none')
														]),
													_List_fromArray(
														[
															$elm$html$Html$text('Cancel')
														])),
													A2(
													$elm$html$Html$button,
													_List_fromArray(
														[
															$elm$html$Html$Events$onClick($author$project$Admin$SaveStudentEdit),
															$elm$html$Html$Attributes$class('px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none')
														]),
													_List_fromArray(
														[
															$elm$html$Html$text('Save Changes')
														]))
												]))
										]))
								]))
						]))
				]));
	});
var $author$project$Admin$DeleteStudent = function (a) {
	return {$: 47, a: a};
};
var $author$project$Admin$EditStudent = function (a) {
	return {$: 46, a: a};
};
var $author$project$Admin$ViewStudentRecord = function (a) {
	return {$: 19, a: a};
};
var $elm$html$Html$td = _VirtualDom_node('td');
var $author$project$Admin$viewStudentRow = function (student) {
	return A2(
		$elm$html$Html$tr,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('hover:bg-gray-50')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm font-medium text-gray-900')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$author$project$Admin$formatDisplayName(student.c))
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm text-gray-500')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(student.d)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm text-gray-500')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(student.ai)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm text-gray-500')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(student.am)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-2')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Admin$ViewStudentRecord(student.d)),
								$elm$html$Html$Attributes$class('w-24 px-2 py-1 bg-green-100 text-green-700 rounded hover:bg-green-200 transition text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('View Records')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Admin$EditStudent(student)),
								$elm$html$Html$Attributes$class('w-24 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Edit')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Admin$DeleteStudent(student)),
								$elm$html$Html$Attributes$class('w-24 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Delete')
							]))
					]))
			]));
};
var $author$project$Admin$viewCreateStudentPage = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('space-y-6')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('bg-white shadow rounded-lg p-6')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex justify-between items-center')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$h2,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-xl font-medium text-gray-900')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Student Management')
									])),
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$Admin$CloseCreateStudentForm),
										$elm$html$Html$Attributes$class('text-gray-500 hover:text-gray-700 flex items-center')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$span,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('mr-1')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('←')
											])),
										$elm$html$Html$text('Back to Submissions')
									]))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('mt-6 space-y-6')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('space-y-2')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$h3,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900 mb-3')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Create New Student')
											])),
										A2(
										$elm$html$Html$label,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$for('studentName'),
												$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Student Name:')
											])),
										A2(
										$elm$html$Html$input,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$type_('text'),
												$elm$html$Html$Attributes$id('studentName'),
												$elm$html$Html$Attributes$value(model.aa),
												$elm$html$Html$Events$onInput($author$project$Admin$UpdateNewStudentName),
												$elm$html$Html$Attributes$placeholder('firstname.lastname (e.g., tyler.smith)'),
												$elm$html$Html$Attributes$class('mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
											]),
										_List_Nil),
										A2(
										$elm$html$Html$p,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('text-sm text-gray-500 mt-1')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Name must be in format: firstname.lastname')
											]))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('mt-6')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick($author$project$Admin$CreateNewStudent),
												$elm$html$Html$Attributes$class('w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Create Student Record')
											]))
									]))
							]))
					])),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('bg-white shadow rounded-lg p-6 mt-6')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$h3,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900 mb-4')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Student Directory')
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('mb-4')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex items-center justify-between mb-4')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('flex-1 max-w-md')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$label,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$for('studentFilterText'),
														$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700 mb-1')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Search Students')
													])),
												A2(
												$elm$html$Html$input,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$type_('text'),
														$elm$html$Html$Attributes$id('studentFilterText'),
														$elm$html$Html$Attributes$placeholder('Search by name or ID'),
														$elm$html$Html$Attributes$value(model.ap),
														$elm$html$Html$Events$onInput($author$project$Admin$UpdateStudentFilterText),
														$elm$html$Html$Attributes$class('w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
													]),
												_List_Nil)
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('flex items-center ml-4 self-end')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$button,
												_List_fromArray(
													[
														$elm$html$Html$Events$onClick($author$project$Admin$RequestAllStudents),
														$elm$html$Html$Attributes$class('flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Refresh')
													]))
											]))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex items-center mt-2')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$span,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('text-sm text-gray-500 mr-2')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Sort by:')
											])),
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick(
												$author$project$Admin$UpdateStudentSortBy(0)),
												$elm$html$Html$Attributes$class(
												A2($author$project$Admin$getStudentSortButtonClass, model, 0))
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Name')
											])),
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick(
												$author$project$Admin$UpdateStudentSortBy(1)),
												$elm$html$Html$Attributes$class(
												A2($author$project$Admin$getStudentSortButtonClass, model, 1))
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Created')
											])),
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick(
												$author$project$Admin$UpdateStudentSortBy(2)),
												$elm$html$Html$Attributes$class(
												A2($author$project$Admin$getStudentSortButtonClass, model, 2))
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Last Active')
											])),
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick($author$project$Admin$ToggleStudentSortDirection),
												$elm$html$Html$Attributes$class('ml-2 px-2 py-1 rounded text-gray-600 hover:bg-gray-100')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(
												(!model.ad) ? '↑' : '↓')
											])),
										A2(
										$elm$html$Html$span,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('ml-4 text-sm text-gray-500')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(
												'Total: ' + ($elm$core$String$fromInt(
													$elm$core$List$length(
														$author$project$Admin$applyStudentFilters(model))) + ' students'))
											]))
									]))
							])),
						model.a ? A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex justify-center my-12')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500')
									]),
								_List_Nil)
							])) : ($elm$core$List$isEmpty(
						$author$project$Admin$applyStudentFilters(model)) ? A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-center py-12 bg-gray-50 rounded-lg')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$p,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-gray-500')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('No students found matching your filters.')
									]))
							])) : A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('overflow-x-auto bg-white')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$table,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('min-w-full divide-y divide-gray-200')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$thead,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('bg-gray-50')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$tr,
												_List_Nil,
												_List_fromArray(
													[
														A2(
														$elm$html$Html$th,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Name')
															])),
														A2(
														$elm$html$Html$th,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Student ID')
															])),
														A2(
														$elm$html$Html$th,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Created')
															])),
														A2(
														$elm$html$Html$th,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Last Active')
															])),
														A2(
														$elm$html$Html$th,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
															]),
														_List_fromArray(
															[
																$elm$html$Html$text('Actions')
															]))
													]))
											])),
										A2(
										$elm$html$Html$tbody,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('bg-white divide-y divide-gray-200')
											]),
										A2(
											$elm$core$List$map,
											$author$project$Admin$viewStudentRow,
											$author$project$Admin$applyStudentFilters(model)))
									]))
							])))
					])),
				function () {
				var _v0 = model.B;
				if (!_v0.$) {
					var student = _v0.a;
					return A2($author$project$Admin$viewEditStudentModal, model, student);
				} else {
					return $elm$html$Html$text('');
				}
			}(),
				function () {
				var _v1 = model.W;
				if (!_v1.$) {
					var student = _v1.a;
					return $author$project$Admin$viewConfirmDeleteModal(student);
				} else {
					return $elm$html$Html$text('');
				}
			}()
			]));
};
var $author$project$Admin$ByBelt = 2;
var $author$project$Admin$ByGradeStatus = 3;
var $author$project$Admin$ByName = 0;
var $author$project$Admin$RefreshSubmissions = {$: 18};
var $author$project$Admin$ShowBeltManagement = {$: 27};
var $author$project$Admin$ShowCreateStudentForm = {$: 22};
var $author$project$Admin$ToggleSortDirection = {$: 13};
var $author$project$Admin$UpdateFilterBelt = function (a) {
	return {$: 10, a: a};
};
var $author$project$Admin$UpdateFilterGraded = function (a) {
	return {$: 11, a: a};
};
var $author$project$Admin$UpdateFilterText = function (a) {
	return {$: 9, a: a};
};
var $author$project$Admin$UpdateSortBy = function (a) {
	return {$: 12, a: a};
};
var $author$project$Admin$filterByBelt = F2(
	function (maybeBelt, submission) {
		if (!maybeBelt.$) {
			var belt = maybeBelt.a;
			return _Utils_eq(submission.z, belt);
		} else {
			return true;
		}
	});
var $author$project$Admin$filterByGraded = F2(
	function (maybeGraded, submission) {
		if (!maybeGraded.$) {
			var isGraded = maybeGraded.a;
			var _v1 = submission.i;
			if (!_v1.$) {
				return isGraded;
			} else {
				return !isGraded;
			}
		} else {
			return true;
		}
	});
var $author$project$Admin$filterByText = F2(
	function (filterText, submission) {
		if ($elm$core$String$isEmpty(filterText)) {
			return true;
		} else {
			var lowercaseFilter = $elm$core$String$toLower(filterText);
			var containsFilter = function (text) {
				return A2(
					$elm$core$String$contains,
					lowercaseFilter,
					$elm$core$String$toLower(text));
			};
			return containsFilter(submission.q) || (containsFilter(submission.N) || containsFilter(submission.z));
		}
	});
var $author$project$Admin$sortSubmissions = F3(
	function (sortBy, direction, submissions) {
		var sortFunction = function () {
			switch (sortBy) {
				case 0:
					return F2(
						function (a, b) {
							return A2($elm$core$Basics$compare, a.q, b.q);
						});
				case 1:
					return F2(
						function (a, b) {
							return A2($elm$core$Basics$compare, a.F, b.F);
						});
				case 2:
					return F2(
						function (a, b) {
							return A2($elm$core$Basics$compare, a.z, b.z);
						});
				default:
					return F2(
						function (a, b) {
							var _v2 = _Utils_Tuple2(a.i, b.i);
							_v2$2:
							while (true) {
								if (!_v2.a.$) {
									if (_v2.b.$ === 1) {
										var _v3 = _v2.b;
										return 0;
									} else {
										break _v2$2;
									}
								} else {
									if (!_v2.b.$) {
										var _v4 = _v2.a;
										return 2;
									} else {
										break _v2$2;
									}
								}
							}
							return A2($elm$core$Basics$compare, a.F, b.F);
						});
			}
		}();
		var sortedList = A2($elm$core$List$sortWith, sortFunction, submissions);
		if (!direction) {
			return sortedList;
		} else {
			return $elm$core$List$reverse(sortedList);
		}
	});
var $author$project$Admin$applyFilters = function (model) {
	return A3(
		$author$project$Admin$sortSubmissions,
		model.ao,
		model.ac,
		A2(
			$elm$core$List$filter,
			$author$project$Admin$filterByGraded(model.ax),
			A2(
				$elm$core$List$filter,
				$author$project$Admin$filterByBelt(model.aw),
				A2(
					$elm$core$List$filter,
					$author$project$Admin$filterByText(model.al),
					model.K))));
};
var $author$project$Admin$getSortButtonClass = F2(
	function (model, sortType) {
		var baseClass = 'px-3 py-1 rounded text-sm';
		return _Utils_eq(model.ao, sortType) ? (baseClass + ' bg-blue-100 text-blue-800 font-medium') : (baseClass + ' text-gray-600 hover:bg-gray-100');
	});
var $elm$html$Html$option = _VirtualDom_node('option');
var $elm$html$Html$select = _VirtualDom_node('select');
var $author$project$Admin$viewFilters = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('bg-white shadow rounded-lg mb-6 p-4')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('flex items-center justify-between mb-4')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$h3,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Game Submissions')
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex space-x-2')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$Admin$ShowCreateStudentForm),
										$elm$html$Html$Attributes$class('ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Manage Students')
									])),
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$Admin$ShowBeltManagement),
										$elm$html$Html$Attributes$class('inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Manage Belts')
									]))
							]))
					])),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('flex flex-col md:flex-row md:items-center md:justify-between mb-4 gap-4')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex-1')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$label,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$for('filterText'),
										$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700 mb-1')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Search')
									])),
								A2(
								$elm$html$Html$input,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$type_('text'),
										$elm$html$Html$Attributes$id('filterText'),
										$elm$html$Html$Attributes$placeholder('Search by name or game'),
										$elm$html$Html$Attributes$value(model.al),
										$elm$html$Html$Events$onInput($author$project$Admin$UpdateFilterText),
										$elm$html$Html$Attributes$class('w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
									]),
								_List_Nil)
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('w-full md:w-auto flex flex-col md:flex-row gap-4')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex-1 md:w-40')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$label,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$for('filterBelt'),
												$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700 mb-1')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Belt')
											])),
										A2(
										$elm$html$Html$select,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$id('filterBelt'),
												$elm$html$Html$Events$onInput($author$project$Admin$UpdateFilterBelt),
												$elm$html$Html$Attributes$class('w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
											]),
										_Utils_ap(
											_List_fromArray(
												[
													A2(
													$elm$html$Html$option,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$value('all')
														]),
													_List_fromArray(
														[
															$elm$html$Html$text('All Belts')
														]))
												]),
											A2(
												$elm$core$List$map,
												function (belt) {
													return A2(
														$elm$html$Html$option,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$value(belt.c)
															]),
														_List_fromArray(
															[
																$elm$html$Html$text(belt.c)
															]));
												},
												model.U)))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex-1 md:w-40')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$label,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$for('filterGraded'),
												$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700 mb-1')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Status')
											])),
										A2(
										$elm$html$Html$select,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$id('filterGraded'),
												$elm$html$Html$Events$onInput($author$project$Admin$UpdateFilterGraded),
												$elm$html$Html$Attributes$class('w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$option,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$value('all')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('All Status')
													])),
												A2(
												$elm$html$Html$option,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$value('graded')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Graded')
													])),
												A2(
												$elm$html$Html$option,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$value('ungraded')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Ungraded')
													]))
											]))
									]))
							]))
					])),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('flex flex-col sm:flex-row justify-between items-center')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex items-center gap-2 mb-2 sm:mb-0')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$span,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-sm text-gray-500')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Sort by:')
									])),
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick(
										$author$project$Admin$UpdateSortBy(0)),
										$elm$html$Html$Attributes$class(
										A2($author$project$Admin$getSortButtonClass, model, 0))
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Name')
									])),
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick(
										$author$project$Admin$UpdateSortBy(1)),
										$elm$html$Html$Attributes$class(
										A2($author$project$Admin$getSortButtonClass, model, 1))
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Date')
									])),
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick(
										$author$project$Admin$UpdateSortBy(2)),
										$elm$html$Html$Attributes$class(
										A2($author$project$Admin$getSortButtonClass, model, 2))
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Belt')
									])),
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick(
										$author$project$Admin$UpdateSortBy(3)),
										$elm$html$Html$Attributes$class(
										A2($author$project$Admin$getSortButtonClass, model, 3))
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Grade Status')
									])),
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$Admin$ToggleSortDirection),
										$elm$html$Html$Attributes$class('ml-2 px-2 py-1 rounded text-gray-600 hover:bg-gray-100')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										(!model.ac) ? '↑' : '↓')
									]))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex items-center')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$Admin$RefreshSubmissions),
										$elm$html$Html$Attributes$class('flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Refresh')
									])),
								A2(
								$elm$html$Html$span,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('ml-4 text-sm text-gray-500')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										'Total: ' + ($elm$core$String$fromInt(
											$elm$core$List$length(
												$author$project$Admin$applyFilters(model))) + ' submissions'))
									]))
							]))
					]))
			]));
};
var $author$project$Admin$CloseStudentRecord = {$: 21};
var $author$project$Admin$DeleteSubmission = function (a) {
	return {$: 55, a: a};
};
var $author$project$Admin$SelectSubmission = function (a) {
	return {$: 7, a: a};
};
var $elm$core$Basics$ge = _Utils_ge;
var $author$project$Admin$viewGradeBadge = function (maybeGrade) {
	if (!maybeGrade.$) {
		var grade = maybeGrade.a;
		var _v1 = (grade.D >= 90) ? _Utils_Tuple2('bg-green-100', 'text-green-800') : ((grade.D >= 70) ? _Utils_Tuple2('bg-blue-100', 'text-blue-800') : ((grade.D >= 60) ? _Utils_Tuple2('bg-yellow-100', 'text-yellow-800') : _Utils_Tuple2('bg-red-100', 'text-red-800')));
		var bgColor = _v1.a;
		var textColor = _v1.b;
		return A2(
			$elm$html$Html$span,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ' + (bgColor + (' ' + textColor)))
				]),
			_List_fromArray(
				[
					$elm$html$Html$text(
					$elm$core$String$fromInt(grade.D) + '/100')
				]));
	} else {
		return A2(
			$elm$html$Html$span,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Ungraded')
				]));
	}
};
var $author$project$Admin$viewStudentSubmissionRow = function (submission) {
	return A2(
		$elm$html$Html$tr,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('hover:bg-gray-50')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm font-medium text-gray-900')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(submission.N)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm text-gray-900')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(submission.z)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm text-gray-500')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(submission.F)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						$author$project$Admin$viewGradeBadge(submission.i)
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-2')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Admin$SelectSubmission(submission)),
								$elm$html$Html$Attributes$class('w-24 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								_Utils_eq(submission.i, $elm$core$Maybe$Nothing) ? 'Grade' : 'View/Edit')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Admin$DeleteSubmission(submission)),
								$elm$html$Html$Attributes$class('w-24 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Delete')
							]))
					]))
			]));
};
var $author$project$Admin$viewStudentRecordPage = F3(
	function (model, student, submissions) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('space-y-6')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('bg-white shadow rounded-lg p-6')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('flex justify-between items-center')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$h2,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('text-xl font-medium text-gray-900')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											'Student Record: ' + $author$project$Admin$formatDisplayName(student.c))
										])),
									A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Events$onClick($author$project$Admin$CloseStudentRecord),
											$elm$html$Html$Attributes$class('text-gray-500 hover:text-gray-700 flex items-center')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$span,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('mr-1')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text('←')
												])),
											$elm$html$Html$text('Back to Submissions')
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('mt-4 grid grid-cols-1 md:grid-cols-3 gap-4')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('bg-gray-50 p-4 rounded-md')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$h3,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('text-sm font-medium text-gray-700')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text('Student ID')
												])),
											A2(
											$elm$html$Html$p,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('mt-1 text-lg')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(student.d)
												]))
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('bg-gray-50 p-4 rounded-md')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$h3,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('text-sm font-medium text-gray-700')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text('Joined')
												])),
											A2(
											$elm$html$Html$p,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('mt-1 text-lg')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(student.ai)
												]))
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('bg-gray-50 p-4 rounded-md')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$h3,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('text-sm font-medium text-gray-700')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text('Last Active')
												])),
											A2(
											$elm$html$Html$p,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('mt-1 text-lg')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(student.am)
												]))
										]))
								]))
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('bg-white shadow rounded-lg overflow-hidden')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('px-6 py-4 border-b border-gray-200')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$h3,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											'All Submissions (' + ($elm$core$String$fromInt(
												$elm$core$List$length(submissions)) + ')'))
										]))
								])),
							$elm$core$List$isEmpty(submissions) ? A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('p-6 text-center')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$p,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('text-gray-500')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text('No submissions found for this student.')
										]))
								])) : A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('overflow-x-auto')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$table,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('min-w-full divide-y divide-gray-200')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$thead,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('bg-gray-50')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$tr,
													_List_Nil,
													_List_fromArray(
														[
															A2(
															$elm$html$Html$th,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text('Game')
																])),
															A2(
															$elm$html$Html$th,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text('Belt')
																])),
															A2(
															$elm$html$Html$th,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text('Submitted')
																])),
															A2(
															$elm$html$Html$th,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text('Grade')
																])),
															A2(
															$elm$html$Html$th,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text('Actions')
																]))
														]))
												])),
											A2(
											$elm$html$Html$tbody,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('bg-white divide-y divide-gray-200')
												]),
											A2($elm$core$List$map, $author$project$Admin$viewStudentSubmissionRow, submissions))
										]))
								]))
						]))
				]));
	});
var $author$project$Admin$viewSubmissionRow = function (submission) {
	return A2(
		$elm$html$Html$tr,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('hover:bg-gray-50')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm font-medium text-gray-900')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$author$project$Admin$formatDisplayName(submission.q))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-xs text-gray-500')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('ID: ' + submission.E)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm text-gray-900')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(submission.N)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm text-gray-900')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(submission.z)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-sm text-gray-500')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(submission.F)
							]))
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap')
					]),
				_List_fromArray(
					[
						$author$project$Admin$viewGradeBadge(submission.i)
					])),
				A2(
				$elm$html$Html$td,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('px-6 py-4 whitespace-nowrap text-sm font-medium flex items-center space-x-2')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Admin$SelectSubmission(submission)),
								$elm$html$Html$Attributes$class('w-24 px-2 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								_Utils_eq(submission.i, $elm$core$Maybe$Nothing) ? 'Grade' : 'View/Edit')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Admin$ViewStudentRecord(submission.E)),
								$elm$html$Html$Attributes$class('w-24 px-2 py-1 bg-green-100 text-green-700 rounded hover:bg-green-200 transition text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Student')
							])),
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$Admin$DeleteSubmission(submission)),
								$elm$html$Html$Attributes$class('w-24 px-2 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Delete')
							]))
					]))
			]));
};
var $author$project$Admin$viewSubmissionList = function (model) {
	var filteredSubmissions = $author$project$Admin$applyFilters(model);
	return $elm$core$List$isEmpty(filteredSubmissions) ? A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('text-center py-12 bg-white rounded-lg shadow')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$p,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('text-gray-500')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text('No submissions found matching your filters.')
					]))
			])) : A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('overflow-x-auto bg-white shadow rounded-lg')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$table,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('min-w-full divide-y divide-gray-200')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$thead,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('bg-gray-50')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$tr,
								_List_Nil,
								_List_fromArray(
									[
										A2(
										$elm$html$Html$th,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Student')
											])),
										A2(
										$elm$html$Html$th,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Game')
											])),
										A2(
										$elm$html$Html$th,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Belt')
											])),
										A2(
										$elm$html$Html$th,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Submitted')
											])),
										A2(
										$elm$html$Html$th,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Grade')
											])),
										A2(
										$elm$html$Html$th,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Actions')
											]))
									]))
							])),
						A2(
						$elm$html$Html$tbody,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('bg-white divide-y divide-gray-200')
							]),
						A2($elm$core$List$map, $author$project$Admin$viewSubmissionRow, filteredSubmissions))
					]))
			]));
};
var $author$project$Admin$viewCurrentPage = function (model) {
	var _v0 = model.t;
	switch (_v0.$) {
		case 0:
			return A2(
				$elm$html$Html$div,
				_List_Nil,
				_List_fromArray(
					[
						$author$project$Admin$viewFilters(model),
						$author$project$Admin$viewSubmissionList(model)
					]));
		case 1:
			var student = _v0.a;
			var submissions = _v0.b;
			return A3($author$project$Admin$viewStudentRecordPage, model, student, submissions);
		case 2:
			return $author$project$Admin$viewCreateStudentPage(model);
		default:
			return $author$project$Admin$viewBeltManagementPage(model);
	}
};
var $author$project$Admin$viewLoadingAuthentication = A2(
	$elm$html$Html$div,
	_List_fromArray(
		[
			$elm$html$Html$Attributes$class('bg-white shadow rounded-lg max-w-md mx-auto p-6 text-center')
		]),
	_List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('flex justify-center my-6')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500')
						]),
					_List_Nil)
				])),
			A2(
			$elm$html$Html$p,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('text-gray-600')
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Signing you in...')
				]))
		]));
var $author$project$Admin$SubmitLogin = {$: 2};
var $author$project$Admin$UpdateLoginEmail = function (a) {
	return {$: 0, a: a};
};
var $author$project$Admin$UpdateLoginPassword = function (a) {
	return {$: 1, a: a};
};
var $author$project$Admin$viewLoginForm = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('bg-white shadow rounded-lg max-w-md mx-auto p-6')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$h2,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('text-xl font-medium text-gray-900 mb-6 text-center')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text('Sign in to Admin Panel')
					])),
				function () {
				var _v0 = model.y;
				if (!_v0.$) {
					var errorMsg = _v0.a;
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('mb-4 bg-red-50 border-l-4 border-red-400 p-4')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$p,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-sm text-red-700')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(errorMsg)
									]))
							]));
				} else {
					return $elm$html$Html$text('');
				}
			}(),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('space-y-4')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_Nil,
						_List_fromArray(
							[
								A2(
								$elm$html$Html$label,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$for('email'),
										$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700 mb-1')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Email Address')
									])),
								A2(
								$elm$html$Html$input,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$type_('email'),
										$elm$html$Html$Attributes$id('email'),
										$elm$html$Html$Attributes$placeholder('admin@example.com'),
										$elm$html$Html$Attributes$value(model.O),
										$elm$html$Html$Events$onInput($author$project$Admin$UpdateLoginEmail),
										$elm$html$Html$Attributes$class('w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
									]),
								_List_Nil)
							])),
						A2(
						$elm$html$Html$div,
						_List_Nil,
						_List_fromArray(
							[
								A2(
								$elm$html$Html$label,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$for('password'),
										$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700 mb-1')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Password')
									])),
								A2(
								$elm$html$Html$input,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$type_('password'),
										$elm$html$Html$Attributes$id('password'),
										$elm$html$Html$Attributes$placeholder('••••••••'),
										$elm$html$Html$Attributes$value(model.P),
										$elm$html$Html$Events$onInput($author$project$Admin$UpdateLoginPassword),
										$elm$html$Html$Attributes$class('w-full border border-gray-300 rounded-md shadow-sm px-3 py-2 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
									]),
								_List_Nil)
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('pt-2')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$Admin$SubmitLogin),
										$elm$html$Html$Attributes$class('w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Sign In')
									]))
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-center mt-4')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$p,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-xs text-gray-500')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('This admin panel requires authentication. Please contact your administrator if you need access.')
									]))
							]))
					]))
			]));
};
var $author$project$Admin$viewMessages = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_Nil,
		_List_fromArray(
			[
				function () {
				var _v0 = model.b;
				if (!_v0.$) {
					var errorMsg = _v0.a;
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('mb-4 bg-red-50 border-l-4 border-red-400 p-4')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$p,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-sm text-red-700')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(errorMsg)
									]))
							]));
				} else {
					return $elm$html$Html$text('');
				}
			}(),
				function () {
				var _v1 = model.k;
				if (!_v1.$) {
					var successMsg = _v1.a;
					return A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('mb-4 bg-green-50 border-l-4 border-green-400 p-4')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$p,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('text-sm text-green-700')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(successMsg)
									]))
							]));
				} else {
					return $elm$html$Html$text('');
				}
			}()
			]));
};
var $author$project$Admin$CloseSubmission = {$: 8};
var $author$project$Admin$SubmitGrade = {$: 16};
var $author$project$Admin$UpdateTempFeedback = function (a) {
	return {$: 15, a: a};
};
var $author$project$Admin$UpdateTempScore = function (a) {
	return {$: 14, a: a};
};
var $elm$html$Html$a = _VirtualDom_node('a');
var $elm$html$Html$Attributes$href = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'href',
		_VirtualDom_noJavaScriptUri(url));
};
var $elm$html$Html$Attributes$max = $elm$html$Html$Attributes$stringProperty('max');
var $elm$html$Html$Attributes$min = $elm$html$Html$Attributes$stringProperty('min');
var $elm$html$Html$Attributes$target = $elm$html$Html$Attributes$stringProperty('target');
var $author$project$Admin$viewSubmissionModal = F2(
	function (model, submission) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center z-50')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('bg-white rounded-lg overflow-hidden shadow-xl max-w-4xl w-full m-4 max-h-[90vh] flex flex-col')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('px-6 py-4 bg-gray-50 border-b border-gray-200 flex justify-between items-center')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$h2,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(submission.q + '\'s Submission')
										])),
									A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Events$onClick($author$project$Admin$CloseSubmission),
											$elm$html$Html$Attributes$class('text-gray-400 hover:text-gray-500')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text('×')
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('px-6 py-2 bg-blue-50 border-b border-gray-200')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Events$onClick(
											$author$project$Admin$ViewStudentRecord(submission.E)),
											$elm$html$Html$Attributes$class('text-sm text-blue-600 hover:text-blue-800')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text('View all submissions for ' + submission.q)
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('p-6 overflow-y-auto flex-grow')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('grid grid-cols-1 md:grid-cols-2 gap-6')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('space-y-6')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$div,
													_List_Nil,
													_List_fromArray(
														[
															A2(
															$elm$html$Html$h3,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900 mb-3')
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text('Submission Details')
																])),
															A2(
															$elm$html$Html$div,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('bg-gray-50 rounded-lg p-4 space-y-3')
																]),
															_List_fromArray(
																[
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('Student Name:')
																				])),
																			A2(
																			$elm$html$Html$p,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text(submission.q)
																				]))
																		])),
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('Student ID:')
																				])),
																			A2(
																			$elm$html$Html$p,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text(submission.E)
																				]))
																		])),
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('Belt Level:')
																				])),
																			A2(
																			$elm$html$Html$p,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text(submission.z)
																				]))
																		])),
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('Game Name:')
																				])),
																			A2(
																			$elm$html$Html$p,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text(submission.N)
																				]))
																		])),
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('Submission Date:')
																				])),
																			A2(
																			$elm$html$Html$p,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text(submission.F)
																				]))
																		])),
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('GitHub Repository:')
																				])),
																			A2(
																			$elm$html$Html$p,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900')
																				]),
																			_List_fromArray(
																				[
																					A2(
																					$elm$html$Html$a,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$href(submission.ay),
																							$elm$html$Html$Attributes$target('_blank'),
																							$elm$html$Html$Attributes$class('text-blue-600 hover:text-blue-800 hover:underline')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text(submission.ay)
																						]))
																				]))
																		])),
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('Notes:')
																				])),
																			A2(
																			$elm$html$Html$p,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900 whitespace-pre-line')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text(submission.aF)
																				]))
																		]))
																]))
														])),
													A2(
													$elm$html$Html$div,
													_List_Nil,
													_List_fromArray(
														[
															A2(
															$elm$html$Html$h3,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900 mb-3')
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text('Current Grade')
																])),
															function () {
															var _v0 = submission.i;
															if (!_v0.$) {
																var grade = _v0.a;
																return A2(
																	$elm$html$Html$div,
																	_List_fromArray(
																		[
																			$elm$html$Html$Attributes$class('bg-gray-50 rounded-lg p-4 space-y-3')
																		]),
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$div,
																			_List_Nil,
																			_List_fromArray(
																				[
																					A2(
																					$elm$html$Html$label,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text('Score:')
																						])),
																					A2(
																					$elm$html$Html$p,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$class('mt-1 text-lg font-bold text-gray-900')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text(
																							$elm$core$String$fromInt(grade.D) + '/100')
																						]))
																				])),
																			A2(
																			$elm$html$Html$div,
																			_List_Nil,
																			_List_fromArray(
																				[
																					A2(
																					$elm$html$Html$label,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text('Feedback:')
																						])),
																					A2(
																					$elm$html$Html$p,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900 whitespace-pre-line')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text(grade.ak)
																						]))
																				])),
																			A2(
																			$elm$html$Html$div,
																			_List_Nil,
																			_List_fromArray(
																				[
																					A2(
																					$elm$html$Html$label,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text('Graded By:')
																						])),
																					A2(
																					$elm$html$Html$p,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text(grade.az)
																						]))
																				])),
																			A2(
																			$elm$html$Html$div,
																			_List_Nil,
																			_List_fromArray(
																				[
																					A2(
																					$elm$html$Html$label,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text('Grading Date:')
																						])),
																					A2(
																					$elm$html$Html$p,
																					_List_fromArray(
																						[
																							$elm$html$Html$Attributes$class('mt-1 text-sm text-gray-900')
																						]),
																					_List_fromArray(
																						[
																							$elm$html$Html$text(grade.aA)
																						]))
																				]))
																		]));
															} else {
																return A2(
																	$elm$html$Html$div,
																	_List_fromArray(
																		[
																			$elm$html$Html$Attributes$class('bg-gray-50 rounded-lg p-4 flex justify-center')
																		]),
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$p,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$class('text-gray-500 italic')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('This submission has not been graded yet.')
																				]))
																		]));
															}
														}()
														]))
												])),
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('space-y-6')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$div,
													_List_Nil,
													_List_fromArray(
														[
															A2(
															$elm$html$Html$h3,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('text-lg font-medium text-gray-900 mb-3')
																]),
															_List_fromArray(
																[
																	$elm$html$Html$text(
																	_Utils_eq(submission.i, $elm$core$Maybe$Nothing) ? 'Add Grade' : 'Update Grade')
																])),
															A2(
															$elm$html$Html$div,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$class('bg-gray-50 rounded-lg p-4 space-y-4')
																]),
															_List_fromArray(
																[
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$for('scoreInput'),
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('Score (0-100):')
																				])),
																			A2(
																			$elm$html$Html$input,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$type_('number'),
																					$elm$html$Html$Attributes$id('scoreInput'),
																					$elm$html$Html$Attributes$min('0'),
																					$elm$html$Html$Attributes$max('100'),
																					$elm$html$Html$Attributes$value(model.af),
																					$elm$html$Html$Events$onInput($author$project$Admin$UpdateTempScore),
																					$elm$html$Html$Attributes$class('mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
																				]),
																			_List_Nil)
																		])),
																	A2(
																	$elm$html$Html$div,
																	_List_Nil,
																	_List_fromArray(
																		[
																			A2(
																			$elm$html$Html$label,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$for('feedbackInput'),
																					$elm$html$Html$Attributes$class('block text-sm font-medium text-gray-700')
																				]),
																			_List_fromArray(
																				[
																					$elm$html$Html$text('Feedback:')
																				])),
																			A2(
																			$elm$html$Html$textarea,
																			_List_fromArray(
																				[
																					$elm$html$Html$Attributes$id('feedbackInput'),
																					$elm$html$Html$Attributes$value(model.ae),
																					$elm$html$Html$Events$onInput($author$project$Admin$UpdateTempFeedback),
																					$elm$html$Html$Attributes$rows(6),
																					$elm$html$Html$Attributes$placeholder('Provide feedback on the game submission...'),
																					$elm$html$Html$Attributes$class('mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm')
																				]),
																			_List_Nil)
																		])),
																	A2(
																	$elm$html$Html$button,
																	_List_fromArray(
																		[
																			$elm$html$Html$Events$onClick($author$project$Admin$SubmitGrade),
																			$elm$html$Html$Attributes$class('w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500')
																		]),
																	_List_fromArray(
																		[
																			$elm$html$Html$text(
																			_Utils_eq(submission.i, $elm$core$Maybe$Nothing) ? 'Submit Grade' : 'Update Grade')
																		]))
																]))
														]))
												]))
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('px-6 py-4 bg-gray-50 border-t border-gray-200 flex justify-end')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Events$onClick($author$project$Admin$CloseSubmission),
											$elm$html$Html$Attributes$class('px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text('Close')
										]))
								]))
						]))
				]));
	});
var $author$project$Admin$viewContent = function (model) {
	var _v0 = model.n;
	switch (_v0.$) {
		case 0:
			return $author$project$Admin$viewLoginForm(model);
		case 1:
			return $author$project$Admin$viewLoadingAuthentication;
		default:
			var user = _v0.a;
			return A2(
				$elm$html$Html$div,
				_List_Nil,
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('bg-white shadow rounded-lg mb-6 p-4 flex justify-between items-center')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex items-center')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('bg-blue-100 text-blue-800 p-2 rounded-full mr-3')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text(
												$elm$core$String$toUpper(
													A2($elm$core$String$left, 1, user.aB)))
											])),
										A2(
										$elm$html$Html$div,
										_List_Nil,
										_List_fromArray(
											[
												A2(
												$elm$html$Html$p,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('text-sm font-medium text-gray-900')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text(user.aB)
													])),
												A2(
												$elm$html$Html$p,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('text-xs text-gray-500')
													]),
												_List_fromArray(
													[
														$elm$html$Html$text(user.aC)
													]))
											]))
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('flex space-x-2')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$button,
										_List_fromArray(
											[
												$elm$html$Html$Events$onClick($author$project$Admin$PerformSignOut),
												$elm$html$Html$Attributes$class('px-3 py-1 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Sign Out')
											]))
									]))
							])),
						model.a ? A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('flex justify-center my-12')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500')
									]),
								_List_Nil)
							])) : A2(
						$elm$html$Html$div,
						_List_Nil,
						_List_fromArray(
							[
								$author$project$Admin$viewMessages(model),
								$author$project$Admin$viewCurrentPage(model)
							])),
						function () {
						var _v1 = model.Y;
						if (!_v1.$) {
							var submission = _v1.a;
							return A2($author$project$Admin$viewSubmissionModal, model, submission);
						} else {
							return $elm$html$Html$text('');
						}
					}(),
						function () {
						var _v2 = model.X;
						if (!_v2.$) {
							var submission = _v2.a;
							return $author$project$Admin$viewConfirmDeleteSubmissionModal(submission);
						} else {
							return $elm$html$Html$text('');
						}
					}()
					]));
	}
};
var $author$project$Admin$view = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('min-h-screen bg-gray-100 py-6 flex flex-col')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 w-full')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$h1,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('text-3xl font-bold text-gray-900 mb-8 text-center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Game Submission Admin')
							])),
						$author$project$Admin$viewContent(model)
					]))
			]));
};
var $author$project$Admin$main = $elm$browser$Browser$element(
	{bC: $author$project$Admin$init, bM: $author$project$Admin$subscriptions, bQ: $author$project$Admin$update, bR: $author$project$Admin$view});
_Platform_export({'Admin':{'init':$author$project$Admin$main(
	$elm$json$Json$Decode$succeed(0))(0)}});}(this));