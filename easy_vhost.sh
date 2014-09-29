#!/bin/sh

#variables
vhost_folder="/etc/apache2/sites";
hosts_file="/etc/hosts";
version="1.1.0";


######
##general functions
#####

#checks if the script is run as root
function is_root
{
	if [[ $EUID -ne 0 ]];
	then
		echo "This script must be run as root." 1>&2;
		exit;
	fi
}

#shows the application message
function message()
{
	clear;
	echo "+-----------------------------------------+";
	echo "| Welcome to easy v-host                  |";
	echo "| for use with the built-in OS X apache2  |";
	echo "| © 2014 Kevin Richter - Version ${version}    |";
	echo "+-----------------------------------------+";
}

#show the programs menu
function menu()
{
	message;

	local i=0;
	menuItems=("to leave the program" "if this is your first run" "to add a virtualhost" "remove a virtualhost" "to edit a virtualhost");

	for item in "${menuItems[@]}";
	do
		echo "Press $i $item";
		((i++))
	done
	read -p "Number: " menu_choice;

	case "$menu_choice" in
		"0") exit;;
		"1") first_run;;
		"2") add_vhost;;
		"3") remove_vhost;;
		"4") edit_vhost;;
		*)	 read -n 1 -p "This is not a valid menu item" && menu;;
	esac
}

#restart apache
function restart_apache()
{
	echo "restarting apache...";
	apachectl restart;
}

function wait_for_confirm()
{
	read -n 1 -p "Press any key to continue";
}

#give a list of all vhosts
function list_vhosts()
{
	echo "0 back to menu"
	local i=0;
	for entry in ${vhost_folder}/*;
	do
		((i++))
		echo ${i} ${entry##/*/}
	done

	read -p "Number: " number;

	if [ "${number}" == "0" ];
	then
		menu;
	else
		menu_select=${number};
	fi
}

#this will create a "/etc/apache2/sites" folder where we will store our configs
#and add a line to the http.conf so that apache knows to load the configs from there
function first_run()
{
	message;

	echo "We will now setup your machine for use with easy vhost.";
	echo "A folder will be create at ${vhost_folder}\nand a line will be added to the apache2 config file."
	read -p "Are you okay with this? (Y/n): " answer;
	if [ "$answer" == "n" ];
	then
		echo "See you later";
	else
		echo "creating folder";
		mkdir -p ${vhost_folder};
		echo "writing to http.conf";
		echo "\nIncludeOptional $vhost_folder" >> /etc/apache2/httpd.conf;

		echo "Your system was setup succesfully!";
		wait_for_confirm;
	fi

	menu;
}


######
##adding a vhost
######

#add vhost function
#asks for a vhost url & the path for it
function add_vhost
{
	message;
	echo "Add a vhost";

	read -p "Url: " host;
	while [[ "$host" == "" ]] ; do
		echo "Please enter a url for your vhost"
		read -p "Url: " host;
	done

	read -e -p "Path: " path;
	while [[ "$path" = "" ]] ; do
		echo "Please enter the path where your files are located"
		read -e -p "Path: " path;
	done

	create_folder ${path}
	write_hosts_entry ${host};
	write_virtual_host ${host} ${path};

	restart_apache;

	wait_for_confirm;
	menu;
}

#show the list of items for the remove function
function remove_vhost()
{
	message;
	echo "Remove a vhost";

	list_vhosts;

	remove_file ${menu_select};

	restart_apache;

	wait_for_confirm;
	menu;
}

#edit a vhost file
function edit_vhost()
{
	message;
	echo "Edit a vhost";

	list_vhosts;

	edit_host_file ${menu_select};

	restart_apache;

	wait_for_confirm;
	menu;
}

function manage()
{
#	message;
#	echo "Manage your virtualhosts";
#
	list_vhosts;

}

#create a folder for the vhosts if it doesnt exist
function create_folder
{
	if [ ! -d "$1" ];
	then
		echo "The folder doesn't exist";
		read -p "Do you want me to create it for you? (y/N): " folder_answer;

		if [ ${folder_answer} == "y" ];
		then
			mkdir -p ${path};
			local parentdir=$(dirname ${path});
			#chown ${whoami} ${path};
			#chmod 755 ${path};
			#chmod the dir and change owner
		fi
	fi
}

#writes entry to /etc/hosts
function write_hosts_entry()
{
	echo "Writing host configuration";
	echo "127.0.0.1\t$1" >> ${hosts_file};
}

#writes the virtual hosts file
function write_virtual_host()
{
	echo "Writing VirtualHost information into apache2 config files";

	echo "<Directory \"$2\">\n" \
	"\tOptions Indexes FollowSymlinks MultiViews\n" \
	"\tAllowOverride All\n" \
	"\tOrder allow,deny\n" \
	"\tRequire all granted\n" \
	"\tAllow from all\n" \
	"</Directory>\n" \
	"<VirtualHost *:80>\n" \
	"\tServerName $1\n" \
	"\tDocumentRoot \"$2\"\n" \
	"</VirtualHost>\n" > ${vhost_folder}/$1;
}

#loops through the config folder and delete the file
#then removes the entry in the /etc/hosts file
function remove_file()
{
	local i=0;
	for entry in ${vhost_folder}/*;
	do
		((i++))
		if [ "$1" == "$i" ];
		then
			read -p "Are you sure that you want to remove the vhost? (Y/n): " removehost_answer;
			if [ "$removehost_answer" == "n" ];
			then
				remove_vhost;
			else
				echo "removing ${entry}";
				rm ${entry};

				echo "removing hosts entry";
				local host=${entry##/*/};
				sed -i .bak "/${host}/d" ${hosts_file};
			fi
			break;
		fi
	done
}

function edit_host_file()
{
	local i=0;
	for entry in ${vhost_folder}/*;
	do
		((i++))
		if [ "$1" == "$i" ];
		then
			nano ${entry}
			break;
		fi
	done
}

#start of the program
is_root;
menu;
