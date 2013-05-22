
internal class PlasticClassModel {
	
	Bool 	isConst
	Str 	className
	Type?	extends
	
	PlasticFieldModel[]		fields	:= [,]
	PlasticMethodModel[]	methods	:= [,]

	** I feel you should know upfront if you want the class to be const or not
	new make(Str className, Bool isConst) {
		this.isConst 	= isConst
		this.className	= className
	}
	
	This extendMixin(Type mixinType) {
		if (isConst && !mixinType.isConst)
			throw PlasticErr(PlasticMsgs.constTypeCannotSubclassNonConstType(className, mixinType))
		if (!isConst && mixinType.isConst)
			throw PlasticErr(PlasticMsgs.nonConstTypeCannotSubclassConstType(className, mixinType))
		if (extends != null)
			throw PlasticErr(PlasticMsgs.canOnlyExtendOneType(className, extends, mixinType))
		if (!mixinType.isMixin)
			throw PlasticErr(PlasticMsgs.canOnlyExtendMixins(className, mixinType))
		
		extends = mixinType
		return this
	}
	
	** All fields have public scope. Why not!? You're not compiling against it!
	This addField(Type fieldType, Str fieldName) {
		if (isConst != fieldType.isConst)
			throw PlasticErr(PlasticMsgs.constTypesMustHaveConstFields(className, fieldType, fieldName))
		
		fields.add(PlasticFieldModel(PlasticVisibility.visPublic, fieldType.isConst, fieldType, fieldName))
		return this
	}
	
	** All methods are given public scope. 
	This overrideMethod(Method method, Str body) {
		if (method.parent != extends)
			throw PlasticErr(PlasticMsgs.overrideMethodDoesNotBelongToSuperType(method, extends))
		if (method.isPrivate || method.isInternal)
			throw PlasticErr(PlasticMsgs.overrideMethodHasWrongScope(method))
		if (!method.isVirtual)
			throw PlasticErr(PlasticMsgs.overrideMethodsMustBeVirtual(method))
		
		methods.add(PlasticMethodModel(true, PlasticVisibility.visPublic, method.returns, method.name, method.params.join(", "), body))
		return this
	}
	
	Str toFantomCode() {
		constKeyword 	:= isConst ? "const " : ""
		extendsKeyword	:= extends == null ? "" : " : ${extends.qname}" 
		
		code := "${constKeyword}class ${className}${extendsKeyword} {\n\n"
		fields.each { code += it.toFantomCode + "\n" }
		
		code += "\n"
		code += "	new make(|This|? f) {
		         		f?.call(this)
		         	}\n"
		code += "\n"

		methods.each { code += it.toFantomCode + "\n" }
		code += "}\n"
		return code
	}
}

internal class PlasticFieldModel {
	PlasticVisibility 	visibility
	Bool				isConst
	Type				type
	Str					name
	
	new make(PlasticVisibility visibility, Bool isConst, Type type, Str name) {
		this.visibility = visibility
		this.isConst	= isConst
		this.type		= type
		this.name		= name
	}

	Str toFantomCode() {
		constKeyword	:= isConst ? "const " : "" 
		return 
		"	${visibility.keyword}${constKeyword}${type.signature} ${name}"
	}
}

internal class PlasticMethodModel {
	Bool			 	isOverride
	PlasticVisibility 	visibility
	Type				returnType
	Str					name
	Str					signature
	Str					body

	new make(Bool isOverride, PlasticVisibility visibility, Type returnType, Str name, Str signature, Str body) {
		this.isOverride	= isOverride
		this.visibility = visibility
		this.returnType	= returnType
		this.name		= name
		this.signature	= signature
		this.body		= body
	}
	
	Str toFantomCode() {
		overrideKeyword	:= isOverride ? "override " : ""
		return
		"	${overrideKeyword}${visibility.keyword}${returnType.signature} ${name}(${signature}) {
		 		${body}
		 	}"
	}
}

internal enum class PlasticVisibility {
	visPrivate	("private "),
	visInternal	("internal "),
	visProtected("protected "),
	visPublic	("");
	
	const Str keyword
	
	private new make(Str keyword) {
		this.keyword = keyword
	}
	
	static PlasticVisibility fromSlot(Slot slot) {
		if (slot.isPrivate)
			return visPrivate
		if (slot.isInternal)
			return visInternal
		if (slot.isProtected)
			return visProtected
		if (slot.isPublic)
			return visPublic
		throw WtfErr("What visibility is ${slot.signature}???")
	}
}
