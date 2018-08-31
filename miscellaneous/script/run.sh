sudo yum -y update

./stop.sh

brook_ver=$(wget --no-check-certificate -qO- https://api.github.com/repos/txthinking/brook/releases | grep -o '"tag_name": ".*"' |head -n 1| sed 's/"//g' | sed 's/tag_name: //g')
new_brook_ver="Brook version "$(echo $brook_ver | sed 's/v//')
old_brook_ver=$(./brook -v)

echo "Current ver: $old_brook_ver. Latest ver: $new_brook_ver."

if [ "$new_brook_ver" != "$old_brook_ver" ]; then

echo Updating...

mv brook brook_bk

wget -q -N --no-check-certificate "https://github.com/txthinking/brook/releases/download/${brook_ver}/brook"

if [ ! -f ./brook ]; then

echo "Failed to download. Reverting..."

mv brook_bk brook

fi

chmod +x brook

fi

echo Starting...

./brook -v

# 2003: Peach
# 5800: Cheng F
# 5432: Cheng F Gay Friend
# 3306: Li Q
# 3389: Weilong

nohup ./brook servers \
	-l ":5432 hahaha5432" \
	-l ":2003 hahaha2003" \
	-l ":3389 hahaha3389" \
	-l ":5800 hahaha5800" \
	-l ":3306 hahaha3306" \
	-tcpDeadline 0 > brook_log.txt 2>brook_err.txt &

