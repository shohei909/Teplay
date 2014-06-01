/*
 * This is based on haxe.macro.ExprTools.
 * 
 * haxe.macro.ExprTools is MIT License.
 * 
 * Copyright (C)2005-2013 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package teplay.core;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.Log;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Position;
import haxe.macro.ExprTools;
import haxe.macro.Format;
import haxe.macro.MacroStringTools;
import haxe.macro.Printer;

/**
 * ...
 * @author shohei909
 */
class TeplayScriptRunner {
	var objects:Array<Dynamic>;
	function new(objects) {
		this.objects = objects;
	}
	
	static public function run(e:Expr, objects:Array<Dynamic>) {
		var runner = new TeplayScriptRunner(objects);
		return runner._run(e);
	}
	
	function _run(e:Expr) {
		try {
			return switch (e.expr) {
				case EBlock(es):
					var v = null;
					for (e in es) { v = getValue(e); }
					voidToNull(v);
				default:
					unsupporedError(e);
			}
		} catch (e:LoopBreak) {
			return switch (e) {
				case Break(p):
					error("Unexpected break", p);
				case Continue(p):
					error("Unexpected continue", p);
			}
		}
	}
	
	
	function getValue(e:Expr):Dynamic {
		if (e == null) return null;
		
		return switch (e.expr) {
			case EConst(CInt(v)): Std.parseInt(v);
			case EConst(CFloat(v)): Std.parseFloat(v);
			case EConst(CString(s)): s;
			case EConst(CIdent("true")): true;
			case EConst(CIdent("false")): false;
			case EConst(CIdent("null")): null;
			case EConst(CIdent("this")): objects[0];
			case EConst(CIdent(s)) : 
				resolve(s, e.pos);
			case EField(e, f) : 
				field(getValue(e), f);
			case EArray(e1, e2):
				var v1:Dynamic = getValue(e1);
				var v2:Dynamic = getValue(e2);
				resolveArray(v1, v2);
			case EVars(arr) :
				for (v in arr) {define(v, e);}
				SpecialValue.Void;
			case EParenthesis(e1), EUntyped(e1), EMeta(_, e1), ECheckType(e1, _), EBlock([e1]): 
				getValue(e1);
			case EBlock(es):
				var v = null;
				objects.push({});
				for (e in es) {v = getValue(e);}
				objects.pop();
				voidToNull(v);
			case EFor( { expr:EIn( { expr:EConst(CIdent(s)) }, e1) }, e2) :
				forLoop(s, e1, e2, e.pos);
				null;
			case EWhile(ec, e, normalWhile) :
				whileLoop(ec, e, normalWhile); 
				null;
			case EBreak :
				throw LoopBreak.Break(e.pos);
			case EContinue :
				throw LoopBreak.Continue(e.pos);
			case EArrayDecl([{ expr : EFor( { expr:EIn( { expr:EConst(CIdent(s)) }, e1) }, e2) }]) :
				forLoop(s, e1, e2, e.pos);
			case EArrayDecl([{ expr : EWhile(ec, e, normalWhile)}]) :
				whileLoop(ec, e, normalWhile);
			case EArrayDecl(el): el.map(getValue);
			case EObjectDecl(fields):
				var obj = {};
				for (field in fields) {
					Reflect.setField(obj, field.field, getValue(field.expr));
				}
				obj;
			case ECall(e, ps): call(e, ps, e.pos);
			case EUnop(op, back, e1):
				var v1:Dynamic = getValue(e1); 
				switch (op) {
					case OpNot: !v1;
					case OpNeg: -v1;
					case OpNegBits: ~v1;
					case OpIncrement :
						var v2 = assign(e1, v1 + 1, e1.pos);
						if (back) v1 else v2;
					case OpDecrement : 
						var v2 = assign(e1, v1 - 1, e1.pos);
						if (back) v1 else v2;
					case _: 
						unsupporedError(e);
				}
			case EBinop(OpAssignOp(op2), e1, e2):
				assign(e1, binop(op2, e, e1, e2), e.pos);
			case EBinop(OpAssign, e1, e2) :
				assign(e1, getValue(e2), e.pos);
			case EBinop(op, e1, e2):
				binop(op, e, e1, e2);
			case ESwitch(e1, cases, edef):
				runSwitch(getValue(e1), cases, edef, e);
			case EIf (e1, e2, null) :
				getValue(e1) ? getValue(e2) : SpecialValue.Void;
			case ETernary(e1, e2, e3), EIf(e1, e2, e3):
				getValue(e1) ? getValue(e2) : getValue(e3);
			case _: 
				unsupporedError(e);
		}
	}
	
	function runSwitch(value, cases:Array<Case>, edef, e) {
		return unsupporedError(e);
	}
	
	function define(v:Var, e:Expr) {
		var obj = objects[objects.length - 1];
		if (v.type != null) throw unsupporedError(e);
		setField(obj, v.name, getValue(v.expr), e.pos);
		return obj;
	}
	
	function binop(op, e, e1, e2):Dynamic {
		var v1:Dynamic = getValue(e1);
		var v2:Dynamic = getValue(e2);
		
		return switch (op) {
			case OpAdd: v1 + v2;
			case OpSub: v1 - v2;
			case OpMult: v1 * v2;
			case OpDiv: v1 / v2;
			case OpMod: v1 % v2;
			case OpEq: v1 == v2;
			case OpNotEq: v1 != v2;
			case OpLt: v1 < v2;
			case OpLte: v1 <= v2;
			case OpGt: v1 > v2;
			case OpGte: v1 >= v2;
			case OpOr: v1 | v2;
			case OpAnd: v1 & v2;
			case OpXor: v1 ^ v2;
			case OpBoolAnd: v1 && v2;
			case OpBoolOr: v1 || v2;
			case OpShl: v1 << v2;
			case OpShr: v1 >> v2;
			case OpUShr: v1 >>> v2;
			case OpInterval: v1 ... v2;
			case _: 
				unsupporedError(e);
		}
	}
	
	
	static function unsupporedError(e:Expr):Dynamic {
		var msg = null;
		trace("");
		trace(e);
		try {
			msg = "Unsupported :" + ExprTools.toString(e);
		} catch (d:Dynamic) {
			msg = "Unsupported :" + e;
		}
		
		return error(msg, e.pos);
	}
	
	function resolve(s:String, pos:Position) {
		var ll = objects.length;
		
		for (i in 0...ll) {
			var obj = objects[ll - 1 - i];
			if ( hasField(obj, s) ) {
				return field(obj, s);
			}
		}
		
		return error(s + " is not found.", pos);
	}
	
	
	function call(e:Expr, params:Array<Expr>, pos:Position) {
		var parent = null, func = null;
		switch (e.expr){
			case EConst(CIdent("trace")) : 
				var p = Context.getPosInfos(pos);
				Log.trace([for (p in params) getValue(p)].join(", "), {fileName:p.file, lineNumber:0, className:"", methodName:""});
				return null;
				
			case EConst(CIdent("format")) : 
				if (params.length != 1) error("Invaild number of arguments", pos);
				return getValue(Format.format(params[0]));
				
			case EField(e1, f) : 
				parent = getValue(e1);
				func = field(parent, f);
			default :
				func = getValue(e);
		}
		
		if (! Reflect.isFunction(func) ) {
			error( ExprTools.toString(e) + " is not function.", pos);
		}
		
		var ps = [];
		for (p in params) {
			ps.push( getValue(p) );
		}
		
		try {
			return Reflect.callMethod(parent, func, ps);
		} catch (d:Dynamic) {
			var msg = Std.string(d);
			var ereg = ~/\([0-9]+ args instead of ([0-9]+)\)/;
			
			if (ereg.match(msg)) {
				var len = Std.parseInt(ereg.matched(1));
				for (p in ps.length...len) ps.push(null);
				return Reflect.callMethod(null, func, ps);
			}else {
				throw d;
			}
		}
	}
	
	function resolveArray(v1, v2:Dynamic) {
		return if (Std.is(v1, StringMap) || Std.is(v1, IntMap) || Std.is(v1, ObjectMap) || Std.is(v1, Array)) {
			v1[v2];
		} else {
			field(v1, v2);
		}
	}
	
	function assign(e:Expr, value:Dynamic, pos:Position) {
		switch(e.expr) {
			case EConst(CIdent(s)) : 
				var ol = objects.length;
				for (i in 0...ol) {
					var obj = objects[ol - i - 1];
					if (hasField(obj, s)) {
						setField(obj, s, value, pos);
						return value;
					} 
				}
			case EField(e, f) : 
				setField(getVariant(e), f, value, pos);
			case EArray(e1, e2):
				var v1:Dynamic = getVariant(e1);
				var v2:Dynamic = getValue(e2);
				
				if (Std.is(v1, StringMap) || Std.is(v1, IntMap) || Std.is(v1, ObjectMap) || Std.is(v1, Array)) {
					v1[v2] = value;
				} else {
					setField(v1, v2, value, pos);
				}
			case _:
				error(ExprTools.toString(e) + " can't be assigned.", pos);
		}
		
		return value;
	}
	
	function getVariant(e:Expr):Dynamic {
		return switch(e.expr) {
			case EConst(CIdent(s)) : 
				resolve(s, e.pos);
			case EField(e, f) : 
				field(getVariant(e), f);
			case EArray(e1, e2):
				var v1:Dynamic = getVariant(e1);
				var v2:Dynamic = getValue(e2);
				resolveArray(v1, v2);
			case _:
				error(ExprTools.toString(e) + " can't be assigned.", e.pos);
		}
	}
	
	static public dynamic function error(msg:String, pos:Position) {
		var p = Context.getPosInfos(pos);
		throw TeplayError.EXECUTE_ERROR(msg, new TeplayPosInfos(p.file, null, p.min, p.max));
		return null;
	}
	
	function forLoop(s:String, e1:Expr, e2:Expr, pos:Position) {
		
		var result = [];
		
		objects.push({});
		
		var obj = objects[objects.length - 1];
		var v:Dynamic = getValue(e1);
		if (Reflect.isFunction(Reflect.field(v, "hasNext")) && Reflect.isFunction(Reflect.field(v, "next"))) {
			var it:Iterator<Dynamic> = v;
			for (i in it) {
				var ol = objects.length;
				try {
					setField(obj, s, i, pos);
					var v = getValue(e2);
					if (!Type.enumEq(v, SpecialValue.Void)) { 
						result.push(v); 
					}
				} catch (b:LoopBreak) {
					switch (b) {
						case Break(_) : 
							objects.splice(ol, objects.length - ol);
							break;
						case Continue(_) : 
							objects.splice(ol, objects.length - ol);
							continue;
					}
				}
			}
		} else if (Reflect.isFunction(Reflect.field(v, "iterator"))) {
			var it:Iterable<Dynamic> = v;
			for (i in it) {
				var ol = objects.length;
				try {
					setField(obj, s, i, pos);
					var v = getValue(e2);
					if (!Type.enumEq(v, SpecialValue.Void)) { 
						result.push(v); 
					}
				} catch (b:LoopBreak) {
					switch (b) {
						case Break(_) : 
							objects.splice(ol, objects.length - ol);
							break;
						case Continue(_) : 
							objects.splice(ol, objects.length - ol);
							continue;
					}
				}
			}
		} else {
			error(ExprTools.toString(e1) + " is not iterable.", e2.pos);
		}
		objects.pop();
		
		return result;
	}
	
	
	function whileLoop(ec, e, normalLoop) {
		if (normalLoop && !getValue(ec)) {
			return [];
		}
		var ol = objects.length;
		var result = [];
		do {
			var ol = objects.length;
			try {
				var v = getValue(e);
				if (!Type.enumEq(v, SpecialValue.Void)) { 
					result.push(v); 
				}
			} catch (b:LoopBreak) {
				switch (b) {
					case Break(_) : 
						objects.splice(ol, objects.length - ol);
						break;
					case Continue(_) : 
						objects.splice(ol, objects.length - ol);
						continue;
				}
			}
		} while (getValue(ec));
		objects.splice(ol, objects.length - ol);
		return result;
	}
	
	static function setField(d:Dynamic, key:String, value:Dynamic, pos:Position) {
		if (Reflect.field(d, "__locked_for_teplay") == true) {
			error(key + " is locked.", pos);
		}
		return Reflect.setField(d, key, voidToNull(value));
	}
	
	static function field(d:Dynamic, key:String) {
		return Reflect.field(d, key);
	}
	
	static function hasField(d:Dynamic, key:String) {
		return Reflect.hasField(d, key);
	}
	
	static function voidToNull(v:Dynamic) {
		return if (Type.enumEq(v, SpecialValue.Void)) null else v;
		
	}
}

private enum LoopBreak {
	Break(Pos:Position);
	Continue(Pos:Position);
}

private enum SpecialValue {
	Void;
}