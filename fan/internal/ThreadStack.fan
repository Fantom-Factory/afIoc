using concurrent::Actor

** I've recently become a fan of threaded stacks - they get me outa a whole lot of trouble!
@Js
internal class ThreadStack {
	Str		stackId
	Obj[]	stack	:= [,]

	new make(Str stackId) {
		this.stackId = stackId
	}

	Void push(Obj? obj) {
		stack.push(obj)
	}
	
	Obj? peek() {
		stack.peek
	}

	Obj? pop() {
		obj := stack.pop
		if (stack.isEmpty)
			Actor.locals.remove(stackId)
		return obj
	}
	
	Void clear() {
		while (peek != null) pop
	}
	
	override Str toStr() {
		str	:= "ThreadStack '${stackId}' is ($stack.size) deep:"
		stack.each { str += "\n  - $it" }
		return str
	}
}


@Js
internal const class OperationsStack {
	private const Str thisStackId
	
	new make(Int regInstCount) {
		thisStackId = regInstCount.toStr.padl(2, '0') + "." + OperationsStack#.qname
	}

	** Caller MUST also call pop() in a finally
	This push(Str operation, Str thing) {
		threadStack := getOrAdd
		// 17 is for "Gathering config"
		op := "${operation}:".justl(17) + " " + thing
		threadStack.push([op, null])
		return this
	}

	Void setServiceId(Str serviceId) {
		threadStack := get(true)
		last := (Str[]) threadStack.stack.last
		last[1] = serviceId
		recurseCheck(threadStack.stack, serviceId)
	}

	Str[] operations() {
		threadStack := get(false)
		return threadStack == null
			? Str#.emptyList
			: threadStack.stack.map |Str?[] item->Str| { item.first }.exclude { it == null }.reverse
	}
	
	Void pop() {
		get(true).pop
	}

	private Void recurseCheck(Obj[] stack, Str serviceId) {
		stack.eachRange(0..-2) |Str?[] item| { 
			if (item[1] != null && serviceId.equalsIgnoreCase(item[1])) {
				serviceIds := stack.map |Str?[] itm->Str?| { return itm[1] }.exclude { it == null }
				throw IocErr(ErrMsgs.scope_serviceRecursion(serviceId, serviceIds))
			}
		}		
	}

	private ThreadStack getOrAdd() {
		Actor.locals.getOrAdd(thisStackId) { ThreadStack(thisStackId) }
	}
	
	private ThreadStack? get(Bool checked) {
		Actor.locals.get(thisStackId) ?: (checked ? throw Err("ThreadStack ${thisStackId} not found") : null)
	}
}

@Js
internal const class ActiveScopeStack {
	private const Str thisStackId
	
	new make(Int regInstCount) {
		thisStackId = regInstCount.toStr.padl(2, '0') + "." + ActiveScopeStack#.qname
	}
	
	Void push(Scope scope) {
		getOrAdd.push(scope)
	}

	Scope? peek() {
		get(false)?.peek
	}
	
	Void pop(Scope scope) {
		stacked := get(false)?.peek
		if (stacked == scope)
			get(false)?.pop
	}
	
	Void clear() {
		get(false)?.clear
	}
	
	private ThreadStack getOrAdd() {
		Actor.locals.getOrAdd(thisStackId) { ThreadStack(thisStackId) }
	}
	
	private ThreadStack? get(Bool checked) {
		Actor.locals.get(thisStackId) ?: (checked ? throw Err("ThreadStack ${thisStackId} not found") : null)
	}
}


