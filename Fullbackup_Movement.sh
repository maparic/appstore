#!/bin/bash

##=======================================================================================================================================================================
##---Begin of Input Parameters---------#
##=======================================================================================================================================================================
storageaccountname="staemeawelzsaptsccs01"
containername="sccfullbackup"
saskeystring="sp=racwl&st=2022-12-29T14:56:03Z&se=2023-12-30T22:56:03Z&spr=https&sv=2021-06-08&sr=c&sig=GYiUkblD20xwSVmuJ%2BlFQOT5pIZV8iSMf%2BBHqmbOtj4%3D"
srclocation="/db2/SCC/backup/SCC/"  ##Ends with /
templocation="/db2/SCC/backup/SCC/DB_SCC_FullBackup_$(date +"%d_%m_%y")" ##Scriptwillcreate
temp2location="/db2/SCC/backup/old_backup_SCC/" ##Ends with /
owner="db2scc"
group="dbsccadm"
##=======================================================================================================================================================================
##--- Function for printing the result
##=======================================================================================================================================================================

printresult()
{
  echo  "+-----------------------------------------------------------------------------+"
  echo "| Date/Time : $(date)" | awk '{print $0 substr("                                                                    ",1,78-length($0)) "|"}'
  echo  " ${functionName} - ${returnMessage} "
  echo  "+-----------------------------------------------------------------------------+"
}

##=======================================================================================================================================================================
##--- End of Input Parameters--------#
##=======================================================================================================================================================================

initialize_dir()
{
    functionName="Initializing the Temporary Location"
    if [ ! -d "$temp2location" ]; then
        echo "$temp2location directory doesnot exist, Please validate the directory. Exiting1"
        exit
    fi

    if [ ! -d "$templocation" ]; then
                echo "$templocation does not exist"
                echo "creating $templocation"
                if mkdir "$templocation" ; then
                        returnMessage="Success"
                        chown $owner:$group $templocation
                        printresult functionName returnMessage
                else
                        returnMessage="Failed"
                        printresult functionName returnMessage
               fi
        else
                echo "$templocation directory exist, Please validate the files. Exiting2"
                exit         
    fi
}

##=======================================================================================================================================================================
##--- Moving Files to Temporary Location--------#
##=======================================================================================================================================================================

movingfiles()
{
    /usr/bin/find $srclocation -type f -exec mv {} $templocation \; 2> /dev/null
}

##=======================================================================================================================================================================
##--- Moving Files to Temporary Location--------#
##=======================================================================================================================================================================

copyblob()
{
    functionName="Copying Files to Azure Blob"
    azcopy copy $templocation "https://$storageaccountname.blob.core.windows.net/$containername?$saskeystring" --recursive
    if [ $? == 0 ]; then
        returnMessage="Success"
        echo "Copy to blob is successful"
        printresult functionName returnMessage
        #mkdir -p /$temp2location/old_backup
        mv $srclocation/* $temp2location
        echo "Blob copy is successful and moved the files to temporary location, Success."
    else
        echo -ne "\n Copy to blob is Failed and the Files are in the $templocation , Exiting3 \n"
        returnMessage="Failed"
        printresult functionName returnMessage
    fi
}


##=======================================================================================================================================================================
#--- It call all the function one by one 
##=======================================================================================================================================================================
initialize_dir
movingfiles
copyblob

