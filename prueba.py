import pandas as pd
import matplotlib.pyplot as plt
import json

# Cambia esta línea a la ruta de tu archivo JSON
file_path = '/home/bully/Desktop/iperf3_cl1.json'

# Intenta leer el archivo JSON
try:
    with open(file_path) as f:
        data = json.load(f)
        print("Datos cargados correctamente:")
except ValueError as e:
    print("Error al cargar el archivo JSON:", e)
except FileNotFoundError:
    print("El archivo no se encontró.")

