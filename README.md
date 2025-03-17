# sourcemanp3

Lines are rendered if they are within the viewport, theoretically this should solve the "slow insertion of lines at beginning of big file" problem. 

Later I found the problem of "slow insertion" not only happens at the end of a big file, which is a bit different than what I initially found. Regardless, this little trick indeed improved performance of inserting a new line (at least this is what I observed on my macOS m2 and dell desktop).
