#!/bin/bash

#Resetear configuración
printf "\n"
echo "--------------------------------------------------"
echo "ELIMINANDO LOS NAMESPACES Y BRIDGES PREEXISTENTES |"
echo "--------------------------------------------------"
printf "\n"
sudo ovs-vsctl emer-reset #Reset config ovs
sudo ovs-vsctl del-br Bridge1 #Borro Bridge1
sudo ip -all netns delete  # Eliminando los Namespaces creados
printf "Ejecuto 'ip netns list' (debería dar resultado vacío):\n\n"
ip netns list
echo "--------------------------------------------------------"
printf "\n"
printf "Ejecuto 'sudo ovs-vsctl show:'\n\n"
sudo ovs-vsctl show
printf "\n"
echo "----------------------"
echo "| CLEAN UP FINALIZADO |"
echo "----------------------"
printf "\n"
#Definir número de clientes
echo "Defina cantidad de clientes:"
read cli
printf "\n"
#Creo bridge
echo "--------------------------"
echo "CREANDO UN BRIDGE CON OVS |"
echo "--------------------------"
sudo ovs-vsctl add-br Bridge1
printf "\n"
echo "Bridge1 ha sido creado"
printf "\n"


#Definimos parámetros Server y asignamos IP
echo "------------------------------------"
echo "CREANDO SERVIDOR PARA PRUEBAS IPERF |"
echo "------------------------------------"
sudo ip link add intss type veth peer name intserv
sudo ip netns add ns_server
sudo ovs-vsctl add-port Bridge1 intss
sudo ip link set dev intserv netns ns_server
printf "\n"
echo "namespace ns_server ha sido creado"
printf "\n"
sudo ip netns exec ns_server ip add add 10.0.0.100/8 dev intserv
sudo ip link set dev Bridge1 up
sudo ip link set dev intss up
sudo ip netns exec ns_server ip link set dev intserv up

#Creo namespaces Clientes
echo "---------------------------------"
echo "CREANDO NAMESPACES PARA CLIENTES |"
echo "---------------------------------"
printf "\n"

for ((i = 1; i <= cli; i++)); do
    pu=$((49999+$i))
    sudo rm ns_c$i
    sudo ip netns exec ns_server iperf3 -s -p $pu -1 --logfile ns_c$i &
    ip=$((100+$i))
    sudo ip netns add ns_c$i
    sudo ip link add int_c$i type veth peer name ints$i
    sudo ip link set dev int_c$i netns ns_c$i
    sudo ovs-vsctl add-port Bridge1 ints$i
    sudo ip netns exec ns_c$i ip add add 10.0.0.$ip/8 dev int_c$i
    printf "\n"
    echo "namespace ns_c$i ha sido creado"
    printf "\n"
    sudo ip link set dev ints$i up
    sudo ip netns exec ns_c$i ip link set dev int_c$i up
    sudo konsole -e ip netns exec ns_c$i iperf3 -c 10.0.0.100 -p $pu -J > iperf3_cl$i &
    echo "---------------------------------------------------------------------"
done