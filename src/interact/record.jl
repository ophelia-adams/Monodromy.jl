function record(fig, xpps, tpp, path, name; framerate=60)
	nframes = length(path)
	for xpp in xpps
		xpp.zpath[] = [xpp.zpath[][1]]
	end
	tpp.zpath[] = [tpp.zpath[][1]]
	record(fig, name, path; framerate = framerate) do z
		tpp.zpath[] = push!(tpp.zpath[],z)
	end
end
