function webm2m4a --description 'Convert WebM --> OGG --> M4A'
	set tmpdir (mktemp -d)
	trap "rm -rf $tmpdir" EXIT

	for f in $argv
		if string match -q -r '\.webm$' $f
			echo "Converting $f to OGG"
			set basename (string replace -r '\.webm$' '' $f)

			ffmpeg -i "$f" -vn -acodec copy "$basename.ogg"
		else if string match -q -r '\.ogg$' $f
			set basename (string replace -r '\.ogg$' '' $f)
		else if string match -q -r '\.oga$' $f
			set basename (string replace -r '\.oga$' '' $f)
		else
			echo "Unsupported file type: $f"
			continue
		end

		echo "Converting $basename.ogg to AIFF"
		ffmpeg -i "$basename.ogg" "$tmpdir/$basename.aiff"
		echo "Converting $basename.aiff to M4A"
		afconvert -v -d aac -f m4af -q 127 -s 0 -u pgcm 2 -b 320000 "$tmpdir/$basename.aiff"
		mv "$tmpdir/$basename.m4a" "$basename.m4a"
	end
end
