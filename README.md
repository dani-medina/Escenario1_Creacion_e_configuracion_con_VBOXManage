# Escenario1_Creacion_e_configuracion_con_VBOXManage



Xera as máquinas necesarias segundo un arquivo CSV (Info-Maquinas.txt).

A idea é xerar un escenario similar ao da imaxe: [E1-LAN](https://github.com/danimedin/Escenario1_Creacion_e_configuracion_con_VBOXManage/blob/main/E1%20-%20Xilgaro%20-%20LAN.jpg?raw=true)

No arquivo Info-Maquinas.txt temos unha táboa coa lista de máquinas e os seus parámetros. Este sería un exemplo.



| NOME        | PLANTILLA                        | IP         | usuario       | Password |
| ----------- | -------------------------------- | ---------- | ------------- | -------- |
| E1-XDC-01   | Windows 2022 Sever - Plantilla   | 10.1.0.100 | administrador | abc123.  |
| E1-XDC-02   | Windows 2022 Sever - Plantilla   | 10.1.0.101 | administrador | abc123.  |
| E1-XFS-01   | Windows 2022 Sever - Plantilla   | 10.1.0.110 | administrador | abc123.  |
| E1-W-01     | Windows 11 Pro - Plantilla       | DHCP       | administrador | renaido  |
| E1-W-02     | Windows 11 Pro - Plantilla       | DHCP       | administrador | renaido  |
| E1-Trono-02 | Windows 11 Pro - Plantilla       | 10.1.0.3   | administrador | renaido  |
| E1-Trono-01 | Ubuntu 24.04 Desktop - Plantilla | 10.1.0.2   | root          | renaido  |



Os scripts crean e configuran cada unha das máquinas e as configura con VBOXMANAGE.

### Crea-Maquinas-E1.bash

O script Crea-Maquinas-E1.bash crea as máquinas VirtualBox, apoiándose en plantillas xeradas anteriormente. Véase [Xera_Plantillas_VirtualBox](https://github.com/danimedin/Xera_Plantillas_VirtualBox). Simplemente crea clons enlazados e configura o hardware.

Ademais crea unha máquina, chamada E1-R-INT, que fará de router entre a rede do anfitrión e a rede E1-R-INT.

Para executalo:

```
bash Crea-Maquinas-E1.bash
```



### Configura-Maquinas-E1.bash

O script Configura-Maquinas-E1.bash configura as máquinas segundo o arquivo CSV. É dicir, ponlle as IPs, GW, nomes, etc. 

Ademais configura a máquina E1-R-INT, coas súas IP, DNS, GW e fai que faga enrutamento.

Podemos chamalo usando un parámetro. 

-  t: Configura todas as máquinas do arquivo CSV.
- MAQUINA: Configura só a máquina indicada. 



Para executalo:

```
bash Configura-Maquinas-E1.bash E1-Trono-01
```





