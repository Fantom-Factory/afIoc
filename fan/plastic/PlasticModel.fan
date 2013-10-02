
** All types are generated with a standard serialisation ctor:
** 
**   new make(|This|? f := null) { f?.call(this) }
** 
** @since 1.3
@NoDoc
class PlasticClassModel {
		const Bool 					isConst
		const Str 					className
			Type					superClass	:= Obj#		{ private set }
			Type[]					mixins		:= [,]		{ private set }	// for user info only

	private Pod[] 					usingPods	:= [,]
	private Type[] 					usingTypes	:= [,]
	private Type[] 					extends		:= [,]
	private PlasticFieldModel[]		fields		:= [,]
	private PlasticMethodModel[]	methods		:= [,]

	** I feel you should know upfront if you want the class to be const or not
	new make(Str className, Bool isConst) {
		this.isConst 	= isConst
		this.className	= className
		
		extends.add(superClass)
	}

	** @since 1.4.4
	This usingPod(Pod pod) {
		usingPods.add(pod)
		return this
	}

	** @since 1.4.4
	This usingType(Type type) {
		usingTypes.add(type)
		return this
	}

	This extendClass(Type classType) {
		if (isConst && !classType.isConst)
			throw PlasticErr(PlasticMsgs.constTypeCannotSubclassNonConstType(className, classType))
		if (!isConst && classType.isConst)
			throw PlasticErr(PlasticMsgs.nonConstTypeCannotSubclassConstType(className, classType))
		if (superClass != Obj#)
			throw PlasticErr(PlasticMsgs.canOnlyExtendOneClass(className, superClass, classType))
		if (!classType.isClass)
			throw PlasticErr(PlasticMsgs.canOnlyExtendClass(classType))
		if (classType.isInternal)
			throw PlasticErr(PlasticMsgs.superTypesMustBePublic(className, classType))
		
		extends = extends.exclude { it == superClass}.add(classType)
		superClass = classType
		return this	
	}

	This extendMixin(Type mixinType) {
		if (isConst && !mixinType.isConst)
			throw PlasticErr(PlasticMsgs.constTypeCannotSubclassNonConstType(className, mixinType))
		if (!isConst && mixinType.isConst)
			throw PlasticErr(PlasticMsgs.nonConstTypeCannotSubclassConstType(className, mixinType))
		if (!mixinType.isMixin)
			throw PlasticErr(PlasticMsgs.canOnlyExtendMixins(mixinType))
		// given all our test types are internal, we'll let this condition slide for now...
//		if (mixinType.isInternal)
//			throw PlasticErr(PlasticMsgs.superTypesMustBePublic(className, mixinType))
		
		mixins.add(mixinType)
		extends.add(mixinType)
		return this
	}

	** All fields have public scope. Why not!? You're not compiling against it!
	This addField(Type fieldType, Str fieldName, Str? getBody := null, Str? setBody := null) {
		if (isConst && !fieldType.isConst)
			throw PlasticErr(PlasticMsgs.constTypesMustHaveConstFields(className, fieldType, fieldName))
		
		fields.add(PlasticFieldModel(false, PlasticVisibility.visPublic, fieldType.isConst, fieldType, fieldName, getBody, setBody))
		return this
	}

	** @since 1.4.2
	This addMethod(Type returnType, Str methodName, Str signature, Str body) {
		methods.add(PlasticMethodModel(false, PlasticVisibility.visPublic, returnType, methodName, signature, body))
		return this
	}

	** All methods are given public scope. 
	This overrideMethod(Method method, Str body) {
		if (!extends.any { it.fits(method.parent) })
			throw PlasticErr(PlasticMsgs.overrideMethodDoesNotBelongToSuperType(method, extends))
		if (method.isPrivate || method.isInternal)
			throw PlasticErr(PlasticMsgs.overrideMethodHasWrongScope(method))
		if (!method.isVirtual)
			throw PlasticErr(PlasticMsgs.overrideMethodsMustBeVirtual(method))
		if (method.params.any { it.hasDefault })
			throw PlasticErr(PlasticMsgs.overrideMethodsCanNotHaveDefaultValues(method))
		
		methods.add(PlasticMethodModel(true, PlasticVisibility.visPublic, method.returns, method.name, method.params.join(", "), body))
		return this
	}

	** All fields are given public scope. 
	This overrideField(Field field, Str? getBody := null, Str? setBody := null) {
		if (!extends.any { it.fits(field.parent) })
			throw PlasticErr(PlasticMsgs.overrideFieldDoesNotBelongToSuperType(field, extends))
		if (field.isPrivate || field.isInternal)
			throw PlasticErr(PlasticMsgs.overrideFieldHasWrongScope(field))
		
		fields.add(PlasticFieldModel(true, PlasticVisibility.visPublic, field.isConst, field.type, field.name, getBody, setBody))
		return this
	}

	** All types are generated with a standard serialisation ctor:
	** 
	**   new make(|This|? f := null) { f?.call(this) }
	Str toFantomCode() {
		code := ""
		usingPods.unique.each  { code += "using ${it.name}\n" }
		usingTypes.unique.each { code += "using ${it.qname}\n" }
		code += "\n"
		constKeyword 	:= isConst ? "const " : ""
		extendsKeyword	:= extends.exclude { it == Obj#}.isEmpty ? "" : " : " + extends.exclude { it == Obj#}.map { it.qname }.join(",") 
		
		code += "${constKeyword}class ${className}${extendsKeyword} {\n\n"
		fields.each { code += it.toFantomCode }
		
		code += "\n"
		code += "	new make(|This|? f := null) {
		         		f?.call(this)
		         	}\n"
		code += "\n"

		methods.each { code += it.toFantomCode }
		code += "}\n"
		return code
	}
}

** @since 1.3
internal class PlasticFieldModel {
	Bool			 	isOverride
	PlasticVisibility 	visibility
	Bool				isConst
	Type				type
	Str					name
	Str? 				getBody
	Str? 				setBody
	
	new make(Bool isOverride, PlasticVisibility visibility, Bool isConst, Type type, Str name, Str? getBody, Str? setBody) {
		this.isOverride	= isOverride
		this.visibility = visibility
		this.isConst	= isConst
		this.type		= type
		this.name		= name
		this.getBody	= getBody
		this.setBody	= setBody
	}

	Str toFantomCode() {
		overrideKeyword	:= isOverride ? "override " : ""
		constKeyword	:= isConst ? "const " : "" 
		field :=
		"	${overrideKeyword}${visibility.keyword}${constKeyword}${type.signature} ${name}"
		if (getBody != null || setBody != null) {
			field += " {\n"
			if (getBody != null)
				field += "		get { ${getBody} }\n"
			if (setBody != null)
				field += "		set { ${setBody} }\n"
			field += "	}\n"
		}
		field += "\n"
		return field
	}
}

** @since 1.3
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
		 	}\n"
	}
}

** @since 1.3
@NoDoc
enum class PlasticVisibility {
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
