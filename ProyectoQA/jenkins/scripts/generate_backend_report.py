#!/usr/bin/env python3
"""
Script para generar reporte CSV de las pruebas del backend (Maven/JUnit)
"""
import os
import xml.etree.ElementTree as ET
import csv
from datetime import datetime
import glob

def parse_junit_xml(xml_file):
    """Parsea un archivo XML de JUnit y retorna los resultados"""
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        
        results = {
            'tests': 0,
            'failures': 0,
            'errors': 0,
            'skipped': 0,
            'time': 0.0,
            'test_cases': []
        }
        
        # Obtener estadísticas generales
        if root.tag == 'testsuite':
            results['tests'] = int(root.get('tests', 0))
            results['failures'] = int(root.get('failures', 0))
            results['errors'] = int(root.get('errors', 0))
            results['skipped'] = int(root.get('skipped', 0))
            results['time'] = float(root.get('time', 0.0))
            
            # Parsear casos de prueba individuales
            for testcase in root.findall('testcase'):
                test_name = testcase.get('name', 'Unknown')
                class_name = testcase.get('classname', 'Unknown')
                time = float(testcase.get('time', 0.0))
                status = 'PASSED'
                
                if testcase.find('failure') is not None:
                    status = 'FAILED'
                elif testcase.find('error') is not None:
                    status = 'ERROR'
                elif testcase.find('skipped') is not None:
                    status = 'SKIPPED'
                
                results['test_cases'].append({
                    'class': class_name,
                    'test': test_name,
                    'status': status,
                    'time': time
                })
        
        return results
    except Exception as e:
        print(f"Error parseando {xml_file}: {e}")
        return None

def generate_backend_csv_report():
    """Genera reporte CSV del backend"""
    # Buscar archivos XML de resultados
    # Buscar en 'backend' (nuevo path) o 'stock-simulator-spring' (path antiguo)
    backend_dirs = [
        os.path.join('backend', 'target', 'surefire-reports'),
        os.path.join('stock-simulator-spring', 'target', 'surefire-reports')
    ]
    reports_dir = 'test-reports/backend'
    
    os.makedirs(reports_dir, exist_ok=True)
    
    xml_files = []
    for backend_dir in backend_dirs:
        if os.path.exists(backend_dir):
            xml_files.extend(glob.glob(os.path.join(backend_dir, '*.xml')))
            break  # Usar el primer directorio que exista
    
    if not xml_files:
        print("No se encontraron archivos XML de pruebas")
        # Crear reporte vacío
        csv_file = os.path.join(reports_dir, 'backend_test_report.csv')
        with open(csv_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['Fecha', 'Total Tests', 'Pasados', 'Fallidos', 'Errores', 'Omitidos', 'Tiempo Total'])
            writer.writerow([datetime.now().strftime('%Y-%m-%d %H:%M:%S'), 0, 0, 0, 0, 0, 0.0])
        return
    
    all_results = {
        'tests': 0,
        'failures': 0,
        'errors': 0,
        'skipped': 0,
        'time': 0.0,
        'test_cases': []
    }
    
    # Parsear todos los archivos XML
    for xml_file in xml_files:
        result = parse_junit_xml(xml_file)
        if result:
            all_results['tests'] += result['tests']
            all_results['failures'] += result['failures']
            all_results['errors'] += result['errors']
            all_results['skipped'] += result['skipped']
            all_results['time'] += result['time']
            all_results['test_cases'].extend(result['test_cases'])
    
    # Calcular tests pasados
    passed = all_results['tests'] - all_results['failures'] - all_results['errors'] - all_results['skipped']
    
    # Generar CSV resumen
    csv_file = os.path.join(reports_dir, 'backend_test_report.csv')
    with open(csv_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['Fecha', 'Total Tests', 'Pasados', 'Fallidos', 'Errores', 'Omitidos', 'Tiempo Total (s)'])
        writer.writerow([
            datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            all_results['tests'],
            passed,
            all_results['failures'],
            all_results['errors'],
            all_results['skipped'],
            round(all_results['time'], 2)
        ])
    
    # Generar CSV detallado de casos de prueba
    detailed_csv = os.path.join(reports_dir, 'backend_test_details.csv')
    with open(detailed_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['Clase', 'Test', 'Estado', 'Tiempo (s)'])
        for test_case in all_results['test_cases']:
            writer.writerow([
                test_case['class'],
                test_case['test'],
                test_case['status'],
                round(test_case['time'], 3)
            ])
    
    print(f"Reporte CSV generado: {csv_file}")
    print(f"Reporte detallado generado: {detailed_csv}")

if __name__ == '__main__':
    generate_backend_csv_report()
