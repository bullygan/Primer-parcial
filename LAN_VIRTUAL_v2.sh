#!/bin/bash
echo "RESETEO DE LA CONFIGURACION ANTERIOR"
echo "---------------------------------------------------------------------"

# Reseteando configuraciones anterior
echo "Eliminando bridge de Open Virtual Switch"
echo "---------------------------------------------------------------------"
sudo ovs-vsctl del-br Bridge1
echo "---------------------------------------------------------------------"

# Eliminando los Namespaces creados
echo "Eliminando los Namespaces creados"
echo "---------------------------------------------------------------------"
sudo ip -all netns delete 
echo "---------------------------------------------------------------------"

echo "CLEAN UP FINALIZADO"
echo "---------------------------------------------------------------------"



#Creo bridge
echo "Creando un bridge con Open Virtual Switch..."
echo "---------------------------------------------------------------------"
sudo ovs-vsctl add-br Bridge1
echo "Bridge1 ha sido creado"
echo "---------------------------------------------------------------------"

#Creo namespaces
echo "Creando namespaces..."
echo "---------------------------------------------------------------------"
sudo ip netns add ns1
echo "namespace ns1 ha sido creado"
sudo ip netns add ns2
echo "namespace ns2 ha sido creado"
echo "---------------------------------------------------------------------"

#Con los comandos siguientes se crean automáticamente las interfaces
sudo ip link add int3 type veth peer name int1
sudo ip link add int4 type veth peer name int2

#Agrego interfaces al Bridge1
sudo ovs-vsctl add-port Bridge1 int1
sudo ovs-vsctl add-port Bridge1 int2

#Asigno interfaces a netns
sudo ip link set dev int3 netns ns1
sudo ip link set dev int4 netns ns2

#Config IPs
sudo ip netns exec ns1 ip add add 10.0.0.100/8 dev int3
sudo ip netns exec ns2 ip add add 10.0.0.101/8 dev int4

#Damos de alta bridge e interfaces
sudo ip link set dev Bridge1 up
sudo ip link set dev int1 up
sudo ip link set dev int2 up
sudo ip netns exec ns1 ip link set dev int3 up
sudo ip netns exec ns2 ip link set dev int4 up
