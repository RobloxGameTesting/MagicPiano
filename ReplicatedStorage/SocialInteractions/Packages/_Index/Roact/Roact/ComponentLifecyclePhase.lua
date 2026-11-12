local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)

return (strict({
	Init = Symbol.named("init"),
	Render = Symbol.named("render"),
	ShouldUpdate = Symbol.named("shouldUpdate"),
	WillUpdate = Symbol.named("willUpdate"),
	DidMount = Symbol.named("didMount"),
	DidUpdate = Symbol.named("didUpdate"),
	WillUnmount = Symbol.named("willUnmount"),
	ReconcileChildren = Symbol.named("reconcileChildren"),
	Idle = Symbol.named("idle")
}, "ComponentLifecyclePhase"))