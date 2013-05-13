
internal class PlasticClassModel {
	
	Bool 	isConst
	Str 	className
	Type?	extends
	
	PlasticFieldModel[]		fields	:= [,]
	PlasticMethodModel[]	methods	:= [,]

	** I feel you should know upfront if you want the class to be const or not
	new make(Bool isConst, Str className) {
		this.isConst 	= isConst
		this.className	= className
	}
	
	This extendMixin(Type mixinType) {
		if (isConst != mixinType.isConst)
			throw Err("Const mixup!")	// TODO: better err msg
		if (extends != null)
			throw Err("Can only extend one class")	// TODO: better err msg
		if (!mixinType.isMixin)
			throw Err("Can only extend mixins")	// TODO: better err msg
		
		extends = mixinType
		return this
	}
	
	** defaults to private
	This addField(Type fieldType, Str fieldName) {
		if (isConst != fieldType.isConst)
			throw Err("Const mixup!")	// TODO: better err msg
		fields.add(PlasticFieldModel(PlasticVisibility.visPrivate, fieldType.isConst, fieldType, fieldName))
		return this
	}
	
	** only public mixin methods allowed
	This overrideMethod(Method method, Str body) {
		if (method.parent != extends)
			throw Err("Wrong method!")	// TODO: better err msg
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
	Str					signature	// TODO: break down into params
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
}
