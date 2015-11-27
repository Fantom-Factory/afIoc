
//L ← Empty list that will contain the sorted nodes
//while there are unmarked nodes do
//    select an unmarked node n
//    visit(n) 
//function visit(node n)
//    if n has a temporary mark then stop (not a DAG)
//    if n is not marked (i.e. has not been visited yet) then
//        mark n temporarily
//        for each node m with an edge from n to m do
//            visit(m)
//        mark n permanently
//        add n to L
** 
** @see `http://en.wikipedia.org/wiki/Topological_sorting`	
@Js
internal class Orderer {

	internal static const Str PLACEHOLDER	:= "AFIOC-PLACEHOLDER"
	internal static const Str DELETE		:= "AFIOC-DELETE"
	internal static const Str NULL			:= "AFIOC-NULL"
	private Obj:OrderedNode nodes			:= Obj:OrderedNode[:] { ordered = true }

	Void addPlaceholder(Obj id, Obj[]? before, Obj[]? after) {
		addOrdered(id, PLACEHOLDER, before, after)
	}

	Void remove(Obj id) {
		addOrdered(id, DELETE, null, null)
	}

	Void addOrdered(Obj id, Obj? object, Obj[]? before, Obj[]? after) {
		id = normaliseStr(id)
		if (nodes.containsKey(id) && !nodes[id].isPlaceholder)
			throw IocErr(ErrMsgs.orderer_configKeyAlreadyAdded(id))
		getOrAdd(id, object ?: NULL, false)

		before?.each |thing| {
			idName	 := thing is ContribCont ? ((ContribCont) thing).key 	  : thing
			optional := thing is ContribCont ? ((ContribCont) thing).optional : false
			idName 	  = normaliseStr(idName)
			getOrAdd(idName, null, optional)	// create placeholder
			node := getOrAdd(id, null, optional)
			if (!node.isBefore.contains(idName))
				node.isBefore.add(idName)
		}

		after?.each |thing| {
			idName	 := thing is ContribCont ? ((ContribCont) thing).key 	  : thing
			optional := thing is ContribCont ? ((ContribCont) thing).optional : false
			idName 	  = normaliseStr(idName)
			node	 := getOrAdd(idName, null, optional)
			if (!node.isBefore.contains(id))
				node.isBefore.add(id)
		}
	}

	Obj?[] toOrderedList() {
		order()
			.exclude { it.payload === PLACEHOLDER || it.payload === DELETE }
			.map 	 { it.payload === NULL ? null : it.payload }
	}

	Void clear() {
		nodes.each { it.payload = null }
		nodes.clear
	}

	internal OrderedNode[] order() {
		nodesIn	 := nodes.dup
		nodesOut := OrderedNode[,]

		while (!nodesIn.isEmpty) {
			ctx := OrderingCtx()
			ctx.withNode(nodesIn.vals[0]) |node| {
				visit(ctx, nodesIn, nodesOut, node)
			}
		}

		return nodesOut
	}

	private Void visit(OrderingCtx ctx, Obj:OrderedNode nodesIn, OrderedNode[] nodesOut, OrderedNode n) {
		// follow the dependencies until we find a node that depends on no-one
		nodesIn
			.findAll { 
				it.isBefore.any |depName| { depName == n.name }
			}
			.each { 
				ctx.withNode(it) |node| {
					// BugFix 1.3.10: ensure we don't visit nodes that have already been moved to nodeOut 
					if (nodesIn.containsKey(node.name))
						visit(ctx, nodesIn, nodesOut, node)
				}
			}

		// move node from nodesIn to nodesOut
		nodesIn.remove(n.name)
		
		// don't move optional nodes that weren't found
		if (n.isPlaceholder.not)
			nodesOut.add(n)
	}	

	private OrderedNode getOrAdd(Obj name, Obj? payload, Bool isOptional) {
		node := nodes.getOrAdd(name) |->Obj| {			
			return OrderedNode(name, payload, isOptional)
		}
		if (payload != null)
			node.payload = payload
		return node
	}
	
	Obj normaliseStr(Obj obj) {
		(obj isnot Str) ? obj : ((Str) obj).trim.lower
	}
}

@Js
internal class OrderedNode {
	Obj 	name
	Obj[] 	isBefore	:= [,]
	Obj? 	payload	
	Bool	isOptional	

	new make(Obj name, Obj? payload, Bool isOptional) {
		this.name 	 	= name
		this.payload 	= payload
		this.isOptional	= isOptional
	}

	Bool isPlaceholder() {
		payload == null
	}

	override Str toStr() {
		"${name}->(" + isBefore.join(",") + ")"
	}
}

@Js
internal class OrderingCtx {
	private OrderedNode[]	nodeStack	:= [,]

	Void withNode(OrderedNode node, |OrderedNode node| operation) {
		nodeStack.push(node)

		try {
			// check for recursion
			nodeStack.eachRange(0..<-1) { 
				if (it == node)
					throw IocErr(ErrMsgs.orderer_configRecursion(stackNames))
			}
	
			if (node.isPlaceholder && node.isOptional.not)
				throw IocErr(ErrMsgs.orderer_configIsPlaceholder(node.name))

			operation.call(node)
		} finally {			
			nodeStack.pop
		}
	}

	Str[] stackNames() {
		nodeStack.map { it.name }
	}

	override Str toStr() {
		stackNames.join(" -> ")
	}
}
