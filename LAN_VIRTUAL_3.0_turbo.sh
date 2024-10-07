#!/bin/bash
#echo "RESETEO DE LA CONFIGURACION ANTERIOR"
#echo "---------------------------------------------------------------------"

#Damos de baja bridge e interfaces
#sudo ip link set dev Bridge1 down
#sudo ip link set dev int1 down
#sudo ip link set dev int2 down
#sudo ip netns exec ns_1 ip link set dev int3 down
#sudo ip netns exec ns_2 ip link set dev int4 down

#Borro interfaces en netns
sudo ip link del dev intss netns ns_server
sudo ip link del dev int_c1 netns ns_c1
sudo ip link del dev int_c2 netns ns_c2
sudo ip link del dev int_c3 netns ns_c3
sudo ip link del dev int_c4 netns ns_c4
sudo ip link del dev int_c5 netns ns_c5
sudo ovs-vsctl del-br Bridge1

#Borro interfaces al Bridge1
#sudo ovs-vsctl del-port Bridge1 int1
#sudo ovs-vsctl del-port Bridge1 int2

#Limpiamos los enlaces virtuales y automáticamente las interfaces

# sudo ip link set dev int3 down
#sudo ip link delete int3 type veth peer name int1
#sudo ip link set dev int4 down
#sudo ip link delete int4 type veth peer name int2 

# Eliminando los Namespaces creados
echo "Eliminando los Namespaces creados"
echo "---------------------------------------------------------------------"
#sudo ip -all netns delete 
echo "---------------------------------------------------------------------"

# Reseteando configuraciones anterior
echo "Eliminando bridge de Open Virtual Switch"
echo "---------------------------------------------------------------------"
#sudo ovs-vsctl del-br Bridge1
echo "---------------------------------------------------------------------"

echo "CLEAN UP FINALIZADO"
echo "---------------------------------------------------------------------"

#Definir número de clientes
echo "Defina cantidad de clientes:"
read cli

#Creo bridge
echo "Creando un bridge con Open Virtual Switch..."
echo "---------------------------------------------------------------------"
sudo ovs-vsctl add-br Bridge1
echo "Bridge1 ha sido creado"
echo "---------------------------------------------------------------------"

#Definimos parámetros Server y asignamos IP
sudo ip link add intss type veth peer name intserv
sudo ip netns add ns_server
sudo ovs-vsctl add-port Bridge1 intss
sudo ip link set dev intserv netns ns_server
echo "namespace ns_server ha sido creado"
sudo ip netns exec ns_server ip add add 10.0.0.100/8 dev intserv
sudo ip link set dev Bridge1 up
sudo ip link set dev intss up
sudo ip netns exec ns_server ip link set dev intserv up

#Creo namespaces Clientes
echo "Creando namespaces..."
echo "---------------------------------------------------------------------"

for ((i = 1; i <= cli; i++)); do
    gnome-terminal -- bash -c "
    pu=$((49999+$i))
    echo 156013842 | sudo -S ip netns exec ns_server iperf3 -s -p $pu -1 &

    ip=$((100+$i))
    sudo ip netns add ns_c$i
    sudo ip link add int_c$i type veth peer name ints$i
    sudo ip link set dev int_c$i netns ns_c$i
    sudo ovs-vsctl add-port Bridge1 ints$i
    sudo ip netns exec ns_c$i ip add add 10.0.0.$ip/8 dev int_c$i
    echo "namespace ns_c$i ha sido creado"
    sudo ip link set dev ints$i up
    sudo ip netns exec ns_c$i ip link set dev int_c$i up
    sudo ip netns exec ns_c$i iperf3 -c 10.0.0.100 -p $pu &; exec bash"
done