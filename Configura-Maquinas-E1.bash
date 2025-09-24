#!/bin/bash



source variables.bash
RUTAACTIVA=$(pwd)
#Modificamos IFS para que non faga saltos no bucle cos espazos dos nomes das variables.
IFS=$'\n'

if [ $# -ne 1 ]; then
	echo Erro nos parametros.
	echo "Primeiro parametro pode ser t =\> crea todas as maquinas do escenario"
	echo "Primeiro parametro pode ser o nome dunha máquina e configura só esa máquina."  
	exit
fi

if [ "$1" = "t" ]; then
	cat ${FICHEROMAQUINAS} > /tmp/ListaMaquinas.txt
else
	grep $1 ${FICHEROMAQUINAS} > /tmp/ListaMaquinas.txt
fi


FICHEROMAQUINAS=/tmp/ListaMaquinas.txt

#Comezamos a configurar os equipos Windows
POWERSHELL="C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" 
for LINEA in $(cat ${FICHEROMAQUINAS} | grep Windows)
#for LINEA in $(cat ${FICHEROMAQUINAS} | grep NADA)
do
	MAQUINA=$(echo ${LINEA} | cut -d : -f 1)
	IP=$(echo ${LINEA} | cut -d : -f 3)
	USUARIO=$(echo ${LINEA} | cut -d : -f 4)
	CONTRASINAL=$(echo ${LINEA} | cut -d : -f 5)
	
	if ! vboxmanage list runningvms | grep "${MAQUINA}" > /dev/null; then
		vboxmanage startvm ${MAQUINA}
	fi
	
	EXITCODE=1
	#Esparamos a que a maquina estea dispoñible para a inxección de comandos
	while [ ${EXITCODE} -ne 0 ];
	do
		vboxmanage guestcontrol ${MAQUINA} \
			--username administrador \
			--password ${CONTRASINAL} \
			run ${POWERSHELL} \
			-- -command Get-Date > /dev/null 2>/dev/null
		EXITCODE=$?
		echo "Esperando a que máquina ${MAQUINA} estea dispoñible para a inxección de comandos"
		sleep 5		
	done
	# Renomeado do equipo
	vboxmanage guestcontrol ${MAQUINA} \
		--username administrador \
		--password ${CONTRASINAL} \
		run  ${POWERSHELL} \
		-- -command Rename-Computer ${MAQUINA} 
	# IP, MASCARA e GATEWAY
	if [ ! "${IP}" = "DHCP" ]; then
		vboxmanage guestcontrol ${MAQUINA} \
			--username administrador \
			--password ${CONTRASINAL} \
			run  ${POWERSHELL} \
			-- -command New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress ${IP} -PrefixLength ${MASCARAINT} -DefaultGateway ${GWINT}

		# DNS
		vboxmanage guestcontrol ${MAQUINA} \
			--username administrador \
			--password ${CONTRASINAL} \
			run  ${POWERSHELL} \
			-- -command Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ${DNSINT}
	fi
	
	# Apagado da máquina
	vboxmanage guestcontrol ${MAQUINA} \
		--username administrador \
		--password ${CONTRASINAL} \
		run  ${POWERSHELL} \
		-- -command Stop-Computer 
done


# Configura Equipos Ubuntu

for LINEA in $(cat ${FICHEROMAQUINAS} | grep Ubuntu)
#for LINEA in $(cat ${FICHEROMAQUINAS} | grep NADA)
do
	MAQUINA=$(echo ${LINEA} | cut -d : -f 1)
	IP=$(echo ${LINEA} | cut -d : -f 3)
	USUARIO=$(echo ${LINEA} | cut -d : -f 4)
	CONTRASINAL=$(echo ${LINEA} | cut -d : -f 5)
	
	if ! vboxmanage list runningvms | grep "${MAQUINA}" > /dev/null; then
		vboxmanage startvm ${MAQUINA}
	fi

	EXITCODE=1
	while [ ${EXITCODE} -ne 0 ];
	do
		vboxmanage guestcontrol ${MAQUINA} \
			--username ${USUARIO} \
			--password ${CONTRASINAL} \
			run --exe "/bin/uptime" > /dev/null 2>/dev/null
		EXITCODE=$?
		echo "Esperando a que máquina ${MAQUINA} estea dispoñible para a inxección de comandos"
		sleep 5s
		
	done
	sed "s/CAMBIAME/${MAQUINA}/g" files/hosts > /tmp/hosts-${MAQUINA}
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/hosts-${MAQUINA} /etc/hosts

	
	sed "s/CAMBIAME/${MAQUINA}/g" files/hostname > /tmp/hostname-${MAQUINA}
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/hostname-${MAQUINA} /etc/hostname


	if [ ! "${IP}" = "DHCP" ]; then
		
		NOMENMCLI=$(vboxmanage guestcontrol ${MAQUINA} \
			--username ${USUARIO} \
			--password ${CONTRASINAL} \
			run --exe "/usr/bin/nmcli" -- -t -f NAME,TYPE con show --active | grep ethernet | cut -f 1 -d : )
		if [ ! -z ${NOMENMCLI} ]; then
			vboxmanage guestcontrol ${MAQUINA} \
				--username ${USUARIO} \
				--password ${CONTRASINAL} \
				run --exe "/usr/bin/nmcli" -- con mod ${NOMENMCLI} ipv4.addresses ${IP}/${MASCARAINT}
			vboxmanage guestcontrol ${MAQUINA} \
				--username ${USUARIO} \
				--password ${CONTRASINAL} \
				run --exe "/usr/bin/nmcli" -- con mod ${NOMENMCLI} ipv4.gateway ${GWINT}
			vboxmanage guestcontrol ${MAQUINA} \
				--username ${USUARIO} \
				--password ${CONTRASINAL} \
				run --exe "/usr/bin/nmcli" -- con mod ${NOMENMCLI} ipv4.dns ${DNSINT}	
			vboxmanage guestcontrol ${MAQUINA} \
				--username ${USUARIO} \
				--password ${CONTRASINAL} \
				run --exe "/usr/bin/nmcli" -- con mod ${NOMENMCLI} ipv4.method manual
			vboxmanage guestcontrol ${MAQUINA} \
				--username ${USUARIO} \
				--password ${CONTRASINAL} \
				run --exe "/usr/bin/nmcli" -- con up ${NOMENMCLI}		
		fi
	fi		
	
	
	vboxmanage controlvm ${MAQUINA} acpipowerbutton
done


#Configuramos equipos Debian Server

for LINEA in $(cat ${FICHEROMAQUINAS} | grep Debian)
#for LINEA in $(cat ${FICHEROMAQUINAS} | grep NADA)
do
	MAQUINA=$(echo ${LINEA} | cut -d : -f 1)
	IP=$(echo ${LINEA} | cut -d : -f 3)
	USUARIO=$(echo ${LINEA} | cut -d : -f 4)
	CONTRASINAL=$(echo ${LINEA} | cut -d : -f 5)
	if ! vboxmanage list runningvms | grep "${MAQUINA}" > /dev/null; then
		vboxmanage startvm ${MAQUINA}
	fi
	
	EXITCODE=1
	#Esparamos a que a maquina estea dispoñible para a inxección de comandos
	while [ ${EXITCODE} -ne 0 ];
	do
		vboxmanage guestcontrol ${MAQUINA} \
			--username ${USUARIO} \
			--password ${CONTRASINAL} \
			run --exe "/bin/uptime" > /dev/null 2>/dev/null
		EXITCODE=$?
		echo "Esperando a que máquina ${MAQUINA} estea dispoñible para a inxección de comandos"
		sleep 5s
			
	done
	sed "s/CAMBIAME/${MAQUINA}/g" files/hosts > /tmp/hosts-${MAQUINA}
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/hosts-${MAQUINA} /etc/hosts

	
	sed "s/CAMBIAME/${MAQUINA}/g" files/hostname > /tmp/hostname-${MAQUINA}
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/hostname-${MAQUINA} /etc/hostname
	if [ ! "${IP}" = "DHCP" ]; then
		sed "s/CAMBIAME/${IP}/g" files/interfaces-INT > /tmp/interfaces-${MAQUINA}
		vboxmanage guestcontrol ${MAQUINA} \
			--username root \
			--password renaido \
			copyto /tmp/interfaces-${MAQUINA} /etc/network/interfaces
		sed "s/CAMBIAME/${DNSINT}/g" files/resolv.conf-INT > /tmp/resolv.conf-${MAQUINA}
		vboxmanage guestcontrol ${MAQUINA} \
			--username root \
			--password renaido \
			copyto /tmp/resolv.conf-${MAQUINA} /etc/resolv.conf
	fi		
	
	
	vboxmanage controlvm ${MAQUINA} acpipowerbutton
done



#Configuramos R-INT


MAQUINA="E1-R-INT"

if [ "$1" = "t" ] || [ "$1" = "E1-R-INT" ]; then
	USUARIO=${USUARIORINT}
	CONTRASINAL=${CONTRASINALRINT}
	if ! vboxmanage list runningvms | grep "${MAQUINA}" > /dev/null; then
		vboxmanage startvm ${MAQUINA}
	fi

	EXITCODE=1
	while [ ${EXITCODE} -ne 0 ];
	do
		vboxmanage guestcontrol ${MAQUINA} \
			--username ${USUARIO} \
			--password ${CONTRASINAL} \
			run --exe "/bin/uptime" > /dev/null 2>/dev/null
		EXITCODE=$?
		echo "Esperando a que máquina ${MAQUINA} estea dispoñible para a inxección de comandos"
		sleep 5s
		
	done

	sed "s/CAMBIAME/${MAQUINA}/g" files/hosts > /tmp/hosts-${MAQUINA}
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/hosts-${MAQUINA} /etc/hosts

	
	sed "s/CAMBIAME/${MAQUINA}/g" files/hostname > /tmp/hostname-${MAQUINA}
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/hostname-${MAQUINA} /etc/hostname
		
	
	sed "s/IPPUBLICA/${IPPUBLICA}/g" files/E1-R-INT/interfaces | \
		sed "s/MASCARAPUBLICA/${MASCARAIPUBLICA}/g" | \
		sed "s/GWPUBLICA/${GWPUBLICA}/g" | \
		sed "s/IPINT/${IPINT}/g" | \
		sed "s/MASCARAINT/${MASCARAINT}/g" \
		> /tmp/interfaces-${MAQUINA}
			 
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/interfaces-${MAQUINA} /etc/network/interfaces
	
	sed "s/DNS/${DNSINT}/g" files/E1-R-INT/resolv.conf > /tmp/resolv.conf-${MAQUINA}	
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/resolv.conf-${MAQUINA} /etc/resolv.conf



	cp files/E1-R-INT/sysctl.conf /tmp
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/sysctl.conf /etc/sysctl.conf





	sed "s/IPPUBLICA/${IPPUBLICA}/g" files/E1-R-INT/nftables.conf | \
		sed "s/IPANFITRION/${IPANFITRION}/g" > /tmp/nftables.conf-${MAQUINA}	

	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto /tmp/nftables.conf-${MAQUINA} /etc/nftables.conf


		

	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		copyto $RUTAACTIVA/crontab-${MAQUINA}  /etc/crontab
	
	vboxmanage guestcontrol ${MAQUINA} \
		--username ${USUARIO} \
		--password ${CONTRASINAL} \
		run --exe "/usr/bin/systemctl" -- enable nftables
	
	vboxmanage controlvm ${MAQUINA} acpipowerbutton	

fi
