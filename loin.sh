#!/bin/bash

BASEDIR=$(readlink -f "$0" | xargs dirname)

function bookmarksAsJson {
	buku -p -j
}

function jsonToLine {
	# both lines append the contents of a json object to one line, but one
	# handles single objects while the other handles arrays
	jq -r '. |
		  (objects | . |  [.title, .tags, .uri, .index|tostring] | join("|")),
		  (. | arrays | .[] | [ .title, .tags, .uri, .index|tostring] | join("|"))'
}

function formatColumns {
	"$BASEDIR"/format-columns.awk
}

function searchAsYouType {
	peco --null
}

function openInBrowser {
	while read -r selectedUrlAndIndex; do
		selectedUrl=${selectedUrlAndIndex%|*}
		xdg-open "$selectedUrl"
	done
}

function searchAndSelectBookmarks {
	bookmarksAsJson |
	jsonToLine |
	formatColumns |
	searchAsYouType
}

function askUserForTag {
	read -r -p "input the tag to add: " tag
	echo "$tag"
}

function tagBookmarkAtIndex {
	index=$1
	tag=$2
	buku --update "$index" --tag "$tag"
}

function tagBookmarks {
	urlsAndIndices=$(searchAndSelectBookmarks)
	tag=$(askUserForTag)
	for urlAndIndex in "${urlsAndIndices[@]}"; do
		index=${urlAndIndex#*|}
		tagBookmarkAtIndex "$index" "$tag"
	done

}

function openBookmarks {
	searchAndSelectBookmarks | openInBrowser
}

# set default mode
MODE="open"

# parse tag mode command line flag
if [ "$1" = "--tag" ]; then
	MODE="tag"
fi

# execute
if [ "$MODE" = "open" ]; then
	openBookmarks
elif [ "$MODE" = "tag" ]; then
	tagBookmarks
fi
