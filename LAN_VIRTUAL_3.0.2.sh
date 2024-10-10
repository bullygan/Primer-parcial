#!/bin/bash

#Resetear configuración
printf "\n"
echo "--------------------------------------------------"
echo "ELIMINANDO LOS NAMESPACES Y BRIDGES PREEXISTENTES |"
echo "--------------------------------------------------"
printf "\n"
sudo ovs-vsctl emer-reset #Reset config ovs
sudo ovs-vsctl del-br ISP #Borro ISP
sudo ovs-vsctl del-br PROVEEDOR #Borro PROVEEDOR
sudo ip -all netns delete  # Eliminando los Namespaces creados
printf "Ejecuto 'ip netns list' (debería dar resultado vacío):\n\n"
ip netns list
echo "--------------------------------------------------------"
printf "\n"
printf "Ejecuto 'sudo ovs-vsctl show:'\n\n"
sudo ovs-vsctl show
printf "\n"
printf "Ejecuto 'sudo ip link show | grep int'\n\n"
sudo ip link show | grep int
printf "\n"
echo "----------------------"
echo "| CLEAN UP FINALIZADO |"
echo "----------------------"
printf "\n"
#Definir número de clientes
echo "Defina cantidad de clientes:"
read cli
printf "\n"
#Definir tiempo a realizar la emulación
echo "Defina tiempo de emulación en seg:"
read time
printf "\n"
#Creo bridge
echo " ---------------------------- "
echo "| CREANDO UN BRIDGE CON OVS  |"
echo " ---------------------------- "
sudo ovs-vsctl add-br ISP # Crea una interfaz brigde llamada ISP con Open Virtual Switch.
sudo ovs-vsctl add-br PROVEEDOR
printf "\n"
echo "Los bridges han sido creado"
printf "\n"


#Definimos parámetros Server y asignamos IP
echo "------------------------------------"
echo "CREANDO SERVIDOR PARA PRUEBAS IPERF |"
echo "------------------------------------"
sudo ip link add intss type veth peer name intserv # Se crea el enlace virtual entre la interfaz intss y la intserv que son las interfaces por las cuales se comunicara nuestro servidor iperf3
sudo ip netns add ns_server # Crea el namespace ns_server donde actuara nuestro servidor de iperf3.
sudo ip link add int2 type veth peer name int1 # Se crea el enlace virtual entre la interfaz del ISP y la del PROVEEDOR que son las interfaces por las cuales se comunicara

#Estas lineas siguientes terminan dandole conexion en los dos extremos a las dos interfaces vinculadas anteriormente creadas en el enlace virtual.
sudo ip link set dev intserv netns ns_server # Se conecta la interfaz intserv en el namespace ns_server.
sudo ovs-vsctl add-port PROVEEDOR intss # Se conecta del lado del switch Bridge1 la interfaz intss
sudo ovs-vsctl add-port PROVEEDOR int2
sudo ovs-vsctl add-port ISP int1
printf "\n"
echo "namespace ns_server ha sido creado"
printf "\n"
sudo ip netns exec ns_server ip add add 10.0.0.100/8 dev intserv # Se asigna un ip a la interfaz intserv en el namespace ns_server.

# Las 3 lineas siguientes dan de alta las 3 interfaces creadas, incluido el Bridge.
sudo ip link set dev PROVEEDOR up
sudo ip link set dev ISP up
sudo ip link set dev intss up
sudo ip link set dev int1 up
sudo ip link set dev int2 up
sudo ip netns exec ns_server ip link set dev intserv up

#Creo namespaces Clientes
echo "---------------------------------"
echo "CREANDO NAMESPACES PARA CLIENTES |"
echo "---------------------------------"
printf "\n"

# Limite de Ancho de Banda Enlace Troncal

sudo tc qdisc add dev int2 root tbf rate 150Mbit burst 10kb limit 20kb


for ((i = 1; i <= cli; i++)); do
    pu=$((49999+$i))
    #sudo rm ns_c$i
    sudo ip netns exec ns_server iperf3 -s -p $pu -1 --logfile ns_c$i & # Ejecuta los servidores iperf3 en distintos puertos para luego poder enviar el trafico desde cada ns cliente.
    sleep 1
    ip=$((100+$i))
    sudo ip netns add ns_c$i # Crea los namespaces ns_c(i) que enviaran tráfico al servidor de iperf3.
    printf "\n"
    echo "namespace ns_c$i ha sido creado"
    printf "\n"
    sleep 1
    sudo ip link add int_c$i type veth peer name intISP$i # Este comando genera c/u de los enlaces virtuales entre el ns cliente y el ISP.
    sudo ip link set dev int_c$i netns ns_c$i # Se conecta cada interfaz int_ci a su correspondiente namespace i.
    sudo ovs-vsctl add-port ISP intISP$i # Lo mismo que la linea de arriba nada mas que del lado del ISP se agrega cada ints(i).
    #Limitamos el Ancho de banda de cada Cliente
    sudo tc qdisc add dev intISP$i root tbf rate 10Mbit burst 10kb limit 20kb
    sudo ip netns exec ns_c$i ip add add 10.0.0.$ip/8 dev int_c$i # En cada ns cliente se le asigna un ip a cada interfaz asociada a ese ns.
    #Estas 2 lineas siguientes dan de alta todas las interfaces iterativamente. 
    sudo ip link set dev intISP$i up
    sudo ip netns exec ns_c$i ip link set dev int_c$i up
    #Esta linea que sigue se encarga de enviar el trafico iperf3 desde cada ns a cada servidor a si puerto correspondiente y el output los transforma a JSON y lo manda a un archivo .json.
    sudo ip netns exec ns_c$i iperf3 -c 10.0.0.100 -p $pu -R # > iperf3_cl$i.json &
    echo "---------------------------------------------------------------------"
done
    sudo ip netns exec ns_c$i iperf3 -c 10.0.0.100 -p $pu -t $time -R & # > iperf3_cl$i.json &
    echo "---------------------------------------------------------------------"
done
sleep $time
echo "Limpieza de interfaces"
sudo ip link show | grep int
# sudo ip link delete int2 type veth peer name int1
sudo ip link delete intss
sudo ip link delete int2

for ((i = 1; i <= cli; i++)); do
sudo ip link delete intISP$i
done
echo "Vemos si quedo alguna interfaz int activas"
echo "--------------------------------------------------------"
sudo ip link show | grep int
echo "--------------------------------------------------------"
