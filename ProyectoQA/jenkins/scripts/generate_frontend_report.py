#!/usr/bin/env python3
"""
Script para generar reporte CSV de las pruebas del frontend (Angular/Karma/Jasmine)
"""
import os
import json
import csv
from datetime import datetime
import glob

def parse_karma_json(json_file):
    """Parsea un archivo JSON de resultados de Karma"""
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        results = {
            'success': 0,
            'failed': 0,
            'skipped': 0,
            'total': 0,
            'test_cases': []
        }
        
        if 'browsers' in data:
            for browser in data['browsers']:
                if 'lastResult' in browser:
                    last_result = browser['lastResult']
                    results['success'] += last_result.get('success', 0)
                    results['failed'] += last_result.get('failed', 0)
                    results['skipped'] += last_result.get('skipped', 0)
                    results['total'] += last_result.get('total', 0)
                    
                    # Parsear casos de prueba
                    if 'suites' in last_result:
                        for suite in last_result['suites']:
                            suite_name = suite.get('description', 'Unknown')
                            for spec in suite.get('specs', []):
                                spec_name = spec.get('description', 'Unknown')
                                status = 'PASSED' if spec.get('success', False) else 'FAILED'
                                if spec.get('skipped', False):
                                    status = 'SKIPPED'
                                
                                results['test_cases'].append({
                                    'suite': suite_name,
                                    'test': spec_name,
                                    'status': status,
                                    'time': spec.get('duration', 0)
                                })
        
        return results
    except Exception as e:
        print(f"Error parseando {json_file}: {e}")
        return None

def parse_coverage_json(json_file):
    """Parsea archivo de cobertura de código"""
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if 'total' in data:
            return {
                'lines': data['total'].get('lines', {}).get('pct', 0),
                'statements': data['total'].get('statements', {}).get('pct', 0),
                'functions': data['total'].get('functions', {}).get('pct', 0),
                'branches': data['total'].get('branches', {}).get('pct', 0)
            }
    except Exception as e:
        print(f"Error parseando cobertura {json_file}: {e}")
    
    return None

def generate_frontend_csv_report():
    """Genera reporte CSV del frontend"""
    # Buscar en 'frontend' (nuevo path) o 'stock-simulator-angular' (path antiguo)
    frontend_dirs = ['frontend', 'stock-simulator-angular']
    reports_dir = 'test-reports/frontend'
    
    os.makedirs(reports_dir, exist_ok=True)
    
    # Buscar resultados de Karma
    karma_results = None
    for frontend_dir in frontend_dirs:
        karma_json_path = os.path.join(frontend_dir, 'karma-results.json')
        if os.path.exists(karma_json_path):
            karma_results = parse_karma_json(karma_json_path)
            break
    
    # Buscar cobertura de código
    coverage_results = None
    coverage_paths = []
    for frontend_dir in frontend_dirs:
        coverage_paths.extend([
            os.path.join(frontend_dir, 'coverage', 'coverage-summary.json'),
            os.path.join(frontend_dir, 'coverage', '**', 'coverage-summary.json')
        ])
    
    for path_pattern in coverage_paths:
        for coverage_file in glob.glob(path_pattern, recursive=True):
            coverage_results = parse_coverage_json(coverage_file)
            if coverage_results:
                break
        if coverage_results:
            break
    
    # Si no hay resultados, crear reporte vacío
    if not karma_results:
        karma_results = {
            'success': 0,
            'failed': 0,
            'skipped': 0,
            'total': 0,
            'test_cases': []
        }
    
    # Generar CSV resumen
    csv_file = os.path.join(reports_dir, 'frontend_test_report.csv')
    with open(csv_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['Fecha', 'Total Tests', 'Pasados', 'Fallidos', 'Omitidos'])
        writer.writerow([
            datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            karma_results['total'],
            karma_results['success'],
            karma_results['failed'],
            karma_results['skipped']
        ])
    
    # Agregar cobertura si está disponible
    if coverage_results:
        coverage_csv = os.path.join(reports_dir, 'frontend_coverage_report.csv')
        with open(coverage_csv, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['Fecha', 'Líneas (%)', 'Declaraciones (%)', 'Funciones (%)', 'Ramas (%)'])
            writer.writerow([
                datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                round(coverage_results['lines'], 2),
                round(coverage_results['statements'], 2),
                round(coverage_results['functions'], 2),
                round(coverage_results['branches'], 2)
            ])
    
    # Generar CSV detallado de casos de prueba
    if karma_results['test_cases']:
        detailed_csv = os.path.join(reports_dir, 'frontend_test_details.csv')
        with open(detailed_csv, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['Suite', 'Test', 'Estado', 'Tiempo (ms)'])
            for test_case in karma_results['test_cases']:
                writer.writerow([
                    test_case['suite'],
                    test_case['test'],
                    test_case['status'],
                    round(test_case['time'], 2)
                ])
    
    print(f"Reporte CSV generado: {csv_file}")
    if coverage_results:
        print(f"Reporte de cobertura generado: {coverage_csv}")

if __name__ == '__main__':
    generate_frontend_csv_report()
