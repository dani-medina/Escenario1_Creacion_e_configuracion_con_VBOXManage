#!/bin/bash


## PREPARANDO ARQUIVO VARIABLES.bash

FICHEIROVARIABLESORIXINAL=variables.bash.orixinal
FICHEIROVARIABLES=variables.bash

NOMETARXETA=$(ip -o -4 route show to default | awk '{print $5; exit}')


IPANFITRION=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}')

TALLER=$(echo "$IPANFITRION" | cut -d. -f3)

ANFITRION=$(echo "$IPANFITRION" | cut -d. -f4)

ANFITRIONPLUS50=$(expr ${ANFITRION} + 50 )

sed  "s/NOMETARXETA/${NOMETARXETA}/g"  ${FICHEIROVARIABLESORIXINAL} | sed "s/TALLER/${TALLER}/g" | sed "s/\bANFITRION\b/${ANFITRION}/g" | sed "s/ANFITRIONPLUS50/${ANFITRIONPLUS50}/g" > ${FICHEIROVARIABLES}   


source ${FICHEIROVARIABLES}


## PREPRANDO ARQUIVO PLANTILLAS
FICHEIROPLANTILLASORIXINAL="Plantillas.txt.orixinal"
FICHEIROPLANTILLAS="Plantillas.txt"
sed  "s/USUARIO/${USER}/g" ${FICHEIROPLANTILLASORIXINAL} > ${FICHEIROPLANTILLAS}   




# Creación da cartafol compartida
if [ ! -e ${HOME}/Compartida-E1 ]; then
	mkdir ${HOME}/Compartida-E1
fi



#Modificamos IFS para que non faga saltos no bucle cos espazos dos nomes das variables.
IFS=$'\n'




#Creamos as máquinas da rede interna coa axuda de FicheroMaquinas
for PLANTILLA in $(cat ${FICHEIROPLANTILLAS} | cut -f 2 -d :);
do
	for LINEA in $(cat ${FICHEROMAQUINAS} | grep "${PLANTILLA}" )
	do
		MAQUINA=$(echo ${LINEA} | cut -d : -f 1)
		NOMESNAPSHOT=$MAQUINA-"SNAPSHOT"
		# Creamos un snapshot por cada plantilla para poder facer clons enlazados só no caso que non exista previamente.
		if ! vboxmanage snapshot "${PLANTILLA}" list | grep ${NOMESNAPSHOT}  > /dev/null; then
			echo Facendo snapshot da plantilla
			vboxmanage snapshot "${PLANTILLA}" take ${NOMESNAPSHOT} 
		fi
		if ! vboxmanage list vms | grep "${MAQUINA}" > /dev/null; then
			echo "CREANDO MAQUINA ${MAQUINA}"
			vboxmanage clonevm ${PLANTILLA} --options=link  --name ${MAQUINA}  --register --snapshot=${NOMESNAPSHOT}
			vboxmanage modifyvm ${MAQUINA} --groups ""
			vboxmanage modifyvm ${MAQUINA} --groups "/E1"
			vboxmanage modifyvm ${MAQUINA} --boot1 disk
			vboxmanage modifyvm ${MAQUINA} --nic1 intnet --intnet1 ${REDEINT}
			vboxmanage modifyvm ${MAQUINA} --macaddress1 auto
			vboxmanage sharedfolder add ${MAQUINA} --name=Compartida-E1 --hostpath=${HOME}/Compartida-E1 --automount 
		fi
	done
done


#Creamos o ROUTER E1-R-INT


MAQUINA="E1-R-INT"
PLANTILLA="Debian 12 Server - Plantilla"
if ! vboxmanage list vms | grep -w ${MAQUINA} > /dev/null; then
	NOMESNAPSHOT=$MAQUINA-"SNAPSHOT"
	# Creamos un snapshot por cada plantilla para poder facer clons enlazados só no caso que non exista previamente.
	if ! vboxmanage snapshot "${PLANTILLA}" list | grep ${NOMESNAPSHOT}  > /dev/null; then
		echo Facendo snapshot da plantilla
		vboxmanage snapshot "${PLANTILLA}" take ${NOMESNAPSHOT} 
	fi
	
	vboxmanage clonevm ${PLANTILLAROUTER} --options=link  --name ${MAQUINA}  --register --snapshot=${NOMESNAPSHOT}
	vboxmanage modifyvm ${MAQUINA} --groups ""
	vboxmanage modifyvm ${MAQUINA} --groups "/E1"
	vboxmanage modifyvm ${MAQUINA} --boot1 disk
	#O primeiro NIC ten que estar en bridge
	vboxmanage modifyvm ${MAQUINA} --nic1 bridged
	vboxmanage modifyvm ${MAQUINA} --bridgeadapter1 ${TARXETABRIDGE}
	vboxmanage modifyvm ${MAQUINA} --macaddress1 auto
	vboxmanage modifyvm ${MAQUINA} --nic2 intnet --intnet2 ${REDEINT}
	vboxmanage modifyvm ${MAQUINA} --macaddress2 auto
	vboxmanage sharedfolder add ${MAQUINA} --name=Compartida-E1 --hostpath=${HOME}/Compartida-E1 --automount 
fi





