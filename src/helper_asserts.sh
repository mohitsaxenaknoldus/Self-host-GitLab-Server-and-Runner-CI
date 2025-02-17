#!/bin/bash
# Structure:dir_edit
manual_assert_file_exists() {
	filepath=$1
	if [ ! -f "$filepath" ]; then
		echo "The ssh key file: $filepath does not exist, so the email address of that ssh-account can not be extracted."
		exit 29
	fi
}

manual_assert_dir_exists() {
	dirpath=$1
	if [ ! -d "$dirpath" ]; then
		echo "The ssh key file: $dirpath does not exist, even though one would expect it does."
		exit 29
	fi
}

manual_assert_dir_not_exists() {
	dirpath=$1
	if [ -d "$dirpath" ]; then
		echo "The ssh key file: $dirpath exists, even though the directory should have been deleted."
		exit 29
	fi
}

manual_assert_equal() {
	left="$1"
	right="$2"
	if [ "$left" != "$right" ]; then
		echo "Error, $left does not equal: $right"
		exit 29
	fi
}

manual_assert_not_equal() {
	left="$1"
	right="$2"
	if [ "$left" == "$right" ]; then
		echo "Error, $left equals: $right"
		exit 29
	fi
}