local skkeleton = {
	bna = { 'びゃ', '' },
	bno = { 'びょ', '' },
	bnu = { 'びゅ', '' },
	ca = { 'か', '' },
	ce = { 'け', '' },
	ci = { 'き', '' },
	cna = { 'きゃ', '' },
	cne = { 'きぇ', '' },
	cno = { 'きょ', '' },
	cnu = { 'きゅ', '' },
	co = { 'こ', '' },
	cu = { 'く', '' },
	gna = { 'ぎゃ', '' },
	gne = { 'ぎぇ', '' },
	gno = { 'ぎょ', '' },
	gnu = { 'ぎゅ', '' },
	hna = { 'ひゃ', '' },
	hne = { 'ひぇ', '' },
	hno = { 'ひょ', '' },
	hnu = { 'ひゅ', '' },
	mna = { 'みゃ', '' },
	mne = { 'みぇ', '' },
	mno = { 'みょ', '' },
	mnu = { 'みゅ', '' },
	nha = { 'にゃ', '' },
	nhe = { 'にぇ', '' },
	nho = { 'にょ', '' },
	nhu = { 'にゅ', '' },
	rha = { 'りゃ', '' },
	rhe = { 'りぇ', '' },
	rho = { 'りょ', '' },
	rhu = { 'りゅ', '' },
	sha = { 'しゃ', '' },
	sho = { 'しょ', '' },
	shu = { 'しゅ', '' },
	zha = { 'じゃ', '' },
	zhe = { 'じぇ', '' },
	zho = { 'じょ', '' },
	zhu = { 'じゅ', '' }
}

return setmetatable(skkeleton, {
	__index = function(_, key)
		if key == 'skkeleton' then
			return skkeleton
		elseif key == 'kensaku' then
			local result = {}
			for k, arr in pairs(skkeleton) do
				table.insert(result, { k, arr[1], #arr[2] })
			end
			return result
		end
	end
})
