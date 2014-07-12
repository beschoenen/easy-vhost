#!/bin/bash

#shows the application message
function message
{
	clear;
	echo "+-----------------------------------------+";
	echo "| Welcome to easy v-host                  |";
	echo "| for use with the build in mac apache2   |";
	echo "| ©2014 Kevin Richter - Version 1.0.0     |";
	echo "+-----------------------------------------+";
}

#checks if the script is run as root
function is_root
{
	if [ "$(id -u)" == "1" ];
	then
		echo "Won't run as root" 1>&2;
		exit 1;
	fi;
}

#restart apache
function restart_apache
{
	echo "restarting apache";
	apachectl restart;
}

#create a folder for the vhosts if it doesnt exist
#unused at the moment
function create_folder
{
	if [ ! -d "$1" ];
	then
		echo "The folder doesn't exist";
		echo "Do you want me to create it for you? (y/N)";
		read -p folder_answer;

		if [ ${folder_answer} == "y" ];
		then
			mkdir $path;
			return 1;
		fi
	fi
	return 0;
}

#writes entry to /et/hosts
function write_hosts
{
	echo "Writing host configuration";
	echo "127.0.0.1\t$1" >> /etc/hosts;
}

#writes the virtual hosts file
function write_virtual_host
{
	echo "Writing VirtualHost information into apache2 config files";

	touch /etc/apache2/sites/$1;

	echo "<Directory \"$2\">\n" \
	"\tOptions Indexes FollowSymlinks MultiViews\n" \
	"\tAllowOverride All\n" \
	"\tOrder allow,deny\n" \
	"\tAllow from all\n" \
	"</Directory>\n" \
	"<VirtualHost *:80>\n" \
	"\tServerName $1\n" \
	"\tDocumentRoot \"$2\"\n" \
	"</VirtualHost>\n" >> /etc/apache2/sites/$1;
}

#gives a list of files in the /etc/apache2/sites
function get_list
{
    i=0;
    for entry in /etc/apache2/sites/*;
    do
        ((i++))
        echo $i ${entry##/*/}
    done
}

#loops through the config folder and delete the file
#then removes the entry in the /etc/hosts file
function remove_file
{
    i=0;
    for entry in /etc/apache2/sites/*;
    do
        ((i++))
        if [ "$number" == "$i" ];
        then
            echo "removing $entry";
            rm ${entry};

            echo "removing hosts entry";
            host=${entry##/*/}
            sed -i .bak "/${host}/d" /etc/hosts
            break;
        fi
	done
}

#show the programs menu
function menu
{
	echo "press 1 to add a virtualhost";
	echo "press 2 to remove a virtualhost";
	echo "press 3 if this is your first run";
	read -p "Number: " menu_choice;

	if [ ${menu_choice} == "1" ];
	then
		add_vhost;
	elif [ ${menu_choice} == "2" ];
	then
		remove_vhost;
	elif [ ${menu_choice} == "3" ];
	then
		first_run;
	else
		echo "not a valid char/number";
		menu;
	fi
}

#add vhost function
#asks for a vhost url & the path for it
function add_vhost
{
	message;

	read -p "Url: " host;
	read -e -p "Path: " path;

	#create_folder ${path}
	write_hosts ${host};
	write_virtual_host ${host} ${path};

	restart_apache;
}

#show the list of items for the remove function
function remove_vhost
{
	message;
	get_list;

	read -p "Number: " number;
	remove_file $number;

	restart_apache;
}

#setup for first run
#this will create a "/etc/apache2/sites" folder where we will store our configs
#and add a line to the http.conf so that apache knows to load the configs from there
function first_run
{
	echo "we will now setup your machine for use with easy vhost";
	echo "i will create a folder and write some stuff to your httpd.conf"
	read -p "are you okay with this? (y/n)" answer;
	if [ ${answer} == "y" ];
	then
		echo "creating folder";
		#mkdir -p /etc/apache2/sites;
		echo "writing to http.conf";
		#echo "Include /private/etc/apache2/sites/*" >> /etc/apache2/httpd.conf;
	else
		echo "see you later";
	fi
}

is_root;
message;
menu;