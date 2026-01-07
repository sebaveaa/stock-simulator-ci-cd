#!/usr/bin/env python3
"""
Script para generar reporte consolidado CSV de todas las pruebas
"""
import os
import csv
from datetime import datetime
import glob

def read_csv_summary(csv_file):
    """Lee un archivo CSV de resumen y retorna los datos"""
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                return row
    except Exception as e:
        print(f"Error leyendo {csv_file}: {e}")
    return None

def generate_consolidated_report():
    """Genera reporte consolidado CSV"""
    reports_dir = 'test-reports'
    backend_report = os.path.join(reports_dir, 'backend', 'backend_test_report.csv')
    frontend_report = os.path.join(reports_dir, 'frontend', 'frontend_test_report.csv')
    frontend_coverage = os.path.join(reports_dir, 'frontend', 'frontend_coverage_report.csv')
    
    # Leer reportes
    backend_data = read_csv_summary(backend_report) if os.path.exists(backend_report) else None
    frontend_data = read_csv_summary(frontend_report) if os.path.exists(frontend_report) else None
    coverage_data = read_csv_summary(frontend_coverage) if os.path.exists(frontend_coverage) else None
    
    # Generar reporte consolidado
    consolidated_csv = os.path.join(reports_dir, 'consolidated_test_report.csv')
    
    with open(consolidated_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        
        # Encabezado
        writer.writerow([
            'Fecha',
            'Componente',
            'Total Tests',
            'Pasados',
            'Fallidos',
            'Errores',
            'Omitidos',
            'Tiempo (s)',
            'Cobertura Líneas (%)',
            'Estado'
        ])
        
        # Backend
        if backend_data:
            total_tests = int(backend_data.get('Total Tests', 0))
            passed = int(backend_data.get('Pasados', 0))
            failed = int(backend_data.get('Fallidos', 0))
            errors = int(backend_data.get('Errores', 0))
            skipped = int(backend_data.get('Omitidos', 0))
            status = 'PASS' if (failed == 0 and errors == 0) else 'FAIL'
            
            writer.writerow([
                backend_data.get('Fecha', datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                'Backend',
                total_tests,
                passed,
                failed,
                errors,
                skipped,
                backend_data.get('Tiempo Total (s)', '0'),
                'N/A',
                status
            ])
        else:
            writer.writerow([
                datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'Backend',
                0, 0, 0, 0, 0, 0.0, 'N/A', 'NO EJECUTADO'
            ])
        
        # Frontend
        if frontend_data:
            total_tests = int(frontend_data.get('Total Tests', 0))
            passed = int(frontend_data.get('Pasados', 0))
            failed = int(frontend_data.get('Fallidos', 0))
            skipped = int(frontend_data.get('Omitidos', 0))
            status = 'PASS' if failed == 0 else 'FAIL'
            coverage = coverage_data.get('Líneas (%)', 'N/A') if coverage_data else 'N/A'
            
            writer.writerow([
                frontend_data.get('Fecha', datetime.now().strftime('%Y-%m-%d %H:%M:%S')),
                'Frontend',
                total_tests,
                passed,
                failed,
                0,  # Errores (no aplica para frontend)
                skipped,
                'N/A',
                coverage,
                status
            ])
        else:
            writer.writerow([
                datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'Frontend',
                0, 0, 0, 0, 0, 'N/A', 'N/A', 'NO EJECUTADO'
            ])
        
        # Resumen total
        if backend_data and frontend_data:
            backend_total = int(backend_data.get('Total Tests', 0))
            backend_passed = int(backend_data.get('Pasados', 0))
            backend_failed = int(backend_data.get('Fallidos', 0)) + int(backend_data.get('Errores', 0))
            
            frontend_total = int(frontend_data.get('Total Tests', 0))
            frontend_passed = int(frontend_data.get('Pasados', 0))
            frontend_failed = int(frontend_data.get('Fallidos', 0))
            
            total_tests = backend_total + frontend_total
            total_passed = backend_passed + frontend_passed
            total_failed = backend_failed + frontend_failed
            overall_status = 'PASS' if total_failed == 0 else 'FAIL'
            
            writer.writerow([
                datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                'TOTAL',
                total_tests,
                total_passed,
                total_failed,
                0,
                0,
                'N/A',
                coverage_data.get('Líneas (%)', 'N/A') if coverage_data else 'N/A',
                overall_status
            ])
    
    print(f"Reporte consolidado generado: {consolidated_csv}")
    
    # Mostrar resumen en consola
    print("\n=== RESUMEN DE PRUEBAS ===")
    if backend_data:
        print(f"Backend: {backend_data.get('Pasados', 0)}/{backend_data.get('Total Tests', 0)} pasados")
    if frontend_data:
        print(f"Frontend: {frontend_data.get('Pasados', 0)}/{frontend_data.get('Total Tests', 0)} pasados")

if __name__ == '__main__':
    generate_consolidated_report()

