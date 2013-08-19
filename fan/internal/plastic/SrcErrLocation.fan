
@NoDoc
const class SrcErrLocation {
	const Uri	srcLocation
	const Str[]	srcCode
	const Int 	errLineNo
	const Str 	errMsg

	new make(Uri srcLocation, Str srcCode, Int errLineNo, Str errMsg) {
		this.srcLocation	= srcLocation
		this.srcCode		= srcCode.splitLines
		this.errLineNo		= errLineNo
		this.errMsg			= errMsg
	}

	Str srcCodeSnippet(Int noOfLinesOfPadding := 5) {
		buf := StrBuf()
		buf.add("  ${srcLocation}").add(" : Line ${errLineNo}\n")
		buf.add("    - ${errMsg}\n\n")
		
		srcCodeSnippetMap(noOfLinesOfPadding).each |src, lineNo| {
			pointer := (lineNo == errLineNo) ? "==>" : "   "
			buf.add("${pointer}${lineNo.toStr.justr(3)}: ${src}\n".replace("\t", "    "))
		}
		
		return buf.toStr
	}
	
	Int:Str srcCodeSnippetMap(Int noOfLinesOfPadding := 5) {
		min := (errLineNo - 1 - noOfLinesOfPadding).max(0)	// -1 so "Line 1" == src[0]
		max := (errLineNo - 1 + noOfLinesOfPadding + 1).min(srcCode.size)
		lines := Utils.makeMap(Int#, Str#)
		(min..<max).each { lines[it+1] = srcCode[it] }
		
		// uniformly remove extra whitespace 
		while (canTrim(lines))
			trim(lines)
		
		return lines
	}

	private Bool canTrim(Int:Str lines) {
		lines.vals.all { it[0].isSpace }
	}

	private Void trim(Int:Str lines) {
		lines.each |val, key| { lines[key] = val[1..-1]  }
	}
	
	override Str toStr() {
		srcCodeSnippet
	}
}