import json
import pandas as pd
import matplotlib.pyplot as plt

# Leer el archivo JSON
with open('iperf3_cl2.json') as f: #Abro el archivo y lo llamo f
	data = json.load(f) # Se cargan los datos json del archivo en data.

# Extraer intervalos y datos de bits por segundo
intervals = data['intervals'] # Adquiero de todo el archvo JSON que es un diccionario, la parte intervals[] que es donde dentro de ahi tengo los valores que voy a querer graficar.
#print(intervals)
type(intervals)

# Genera las dos listas adicionales que luego van a ser mis variables para graficar. Por eso las genero vacias para luego llenarla con los valores que hay en intervals.
time_points = []
bps_values = []

for interval in intervals:
    start = interval['sum']['start'] # con corchetes voy sacando los valores del diccionario. Aca entramos en dos niveles primero a sum dentro de interval y dps dentro de sum a start y lo guardo en una variable start.
    end = interval['sum']['end']
    bps = interval['sum']['bits_per_second']
    
    time_points.append(start + (end - start) / 2)  # Promedio de tiempo y voy agregando los valores que voy obteniendo del for en las listas que defini mas arriba. En este caso time_points.
    bps_values.append(bps) # Los datos de tasas obtenidos de intervals se van agregando a la lista bps_values que cree anteriormente.

with open('iperf3_cl1.json') as f1:
    data = json.load(f1)
for interval in intervals:
    start = interval['sum']['start']
    end = interval['sum']['end']
    bps = interval['sum']['bits_per_second']
    
    time_points.append(start + (end - start) / 2)  # Promedio de tiempo
    bps_values.append(bps)

# Crear un DataFrame
#Con los datos ya en las listas creo un Dataframe con pandas que nos relaciona los datos y nos facilita a la hora de graficar y manipular datos.
df = pd.DataFrame({
    'Time (s)': time_points,
    'Bits per Second': bps_values	
})

print(df)
# Crear la gráfica
plt.figure(figsize=(10, 5))
plt.plot(df['Time (s)'], df['Bits per Second'], marker='o')

#plt.plot(time_points, bps_values, marker='o')

plt.title('Rendimiento de iperf a lo largo del tiempo')
plt.xlabel('Tiempo (s)')
plt.ylabel('Bits por segundo')
#plt.yscale('log')  # Usar escala logarítmica para mejor visualización
plt.grid()
plt.xticks(rotation=45)
plt.tight_layout()

# Mostrar la gráfica
plt.show()