local NoopRenderer = {}

function NoopRenderer.isHostObject(p): boolean
	return p == nil
end

function NoopRenderer.mountHostNode(_, _) end

function NoopRenderer.unmountHostNode(_, _) end

function NoopRenderer.updateHostNode(_, p, _)
	return p
end

return NoopRenderer