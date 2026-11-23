--!strict
-- Cria uma Instance com propriedades e filhos numa chamada só (Parent por último).
return function(className: string, props: { [string]: any }, children: { Instance }?): any
	local inst: any = Instance.new(className :: any)
	for key, value in props do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	inst.Parent = props.Parent
	return inst
end
