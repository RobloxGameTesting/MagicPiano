local v = {
	0.1,
	0.2,
	0.3,
	0.4,
	0.5,
	0.6,
	0.7,
	0.8,
	0.9,
	1
}

local v2 = {}

local function scaleSequence(sequence, p)
	local numberSequenceKeypoints = table.create(#sequence.Keypoints)

	for k, keypoint in sequence.Keypoints do
		numberSequenceKeypoints[k] = NumberSequenceKeypoint.new(
			keypoint.Time,
			keypoint.Value * p,
			keypoint.Envelope * p
		)
	end

	return NumberSequence.new(numberSequenceKeypoints)
end

local function getSizes(p, p2)
	local v3 = v2[p]

	if v3 then
		return v3
	end

	local result = table.create(#v)

	for k, v4 in v do
		if v4 == 1 then
			result[k] = p2
		else
			result[k] = scaleSequence(p2, v4)
		end
	end

	v2[p] = result
	return result
end

return getSizes