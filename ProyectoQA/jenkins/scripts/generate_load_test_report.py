#!/usr/bin/env python3
"""
Script para generar reportes consolidados de pruebas de carga desde resultados de JMeter.
"""

import sys
import csv
import json
import os
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional

def parse_jtl_file(jtl_file: str) -> List[Dict]:
    """
    Parsea el archivo JTL de JMeter y retorna una lista de resultados.
    """
    results = []
    
    if not os.path.exists(jtl_file):
        print(f"Error: Archivo JTL no encontrado: {jtl_file}")
        return results
    
    try:
        with open(jtl_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                results.append(row)
    except Exception as e:
        print(f"Error parseando archivo JTL: {e}")
        return results
    
    return results

def calculate_metrics(results: List[Dict]) -> Dict:
    """
    Calcula métricas agregadas de los resultados.
    """
    if not results:
        return {}
    
    # Convertir tiempos a numéricos
    response_times = []
    success_count = 0
    error_count = 0
    total_bytes = 0
    total_requests = len(results)
    
    endpoint_stats = {}
    
    for result in results:
        try:
            # Response time
            elapsed = float(result.get('elapsed', 0))
            response_times.append(elapsed)
            
            # Success/Error
            success = result.get('success', 'false').lower() == 'true'
            if success:
                success_count += 1
            else:
                error_count += 1
            
            # Bytes
            bytes_val = int(result.get('bytes', 0))
            total_bytes += bytes_val
            
            # Estadísticas por endpoint
            label = result.get('label', 'Unknown')
            if label not in endpoint_stats:
                endpoint_stats[label] = {
                    'count': 0,
                    'success': 0,
                    'error': 0,
                    'total_time': 0,
                    'min_time': float('inf'),
                    'max_time': 0
                }
            
            endpoint_stats[label]['count'] += 1
            endpoint_stats[label]['total_time'] += elapsed
            if success:
                endpoint_stats[label]['success'] += 1
            else:
                endpoint_stats[label]['error'] += 1
            
            if elapsed < endpoint_stats[label]['min_time']:
                endpoint_stats[label]['min_time'] = elapsed
            if elapsed > endpoint_stats[label]['max_time']:
                endpoint_stats[label]['max_time'] = elapsed
                
        except (ValueError, KeyError) as e:
            continue
    
    # Calcular estadísticas generales
    response_times.sort()
    metrics = {
        'total_requests': total_requests,
        'success_count': success_count,
        'error_count': error_count,
        'error_percentage': (error_count / total_requests * 100) if total_requests > 0 else 0,
        'avg_response_time': sum(response_times) / len(response_times) if response_times else 0,
        'min_response_time': min(response_times) if response_times else 0,
        'max_response_time': max(response_times) if response_times else 0,
        'median_response_time': response_times[len(response_times) // 2] if response_times else 0,
        'p95_response_time': response_times[int(len(response_times) * 0.95)] if len(response_times) > 0 else 0,
        'p99_response_time': response_times[int(len(response_times) * 0.99)] if len(response_times) > 0 else 0,
        'total_bytes': total_bytes,
        'endpoint_stats': endpoint_stats
    }
    
    # Calcular estadísticas agregadas por endpoint
    for endpoint, stats in endpoint_stats.items():
        stats['avg_time'] = stats['total_time'] / stats['count'] if stats['count'] > 0 else 0
        stats['error_percentage'] = (stats['error'] / stats['count'] * 100) if stats['count'] > 0 else 0
        stats['success_percentage'] = (stats['success'] / stats['count'] * 100) if stats['count'] > 0 else 0
    
    return metrics

def generate_csv_report(metrics: Dict, output_file: str):
    """
    Genera un reporte CSV consolidado.
    """
    output_path = Path(output_file)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        
        # Encabezado general
        writer.writerow(['Métrica', 'Valor'])
        writer.writerow(['Total de Requests', metrics['total_requests']])
        writer.writerow(['Requests Exitosos', metrics['success_count']])
        writer.writerow(['Requests con Error', metrics['error_count']])
        writer.writerow(['Porcentaje de Errores (%)', f"{metrics['error_percentage']:.2f}"])
        writer.writerow(['Tiempo de Respuesta Promedio (ms)', f"{metrics['avg_response_time']:.2f}"])
        writer.writerow(['Tiempo de Respuesta Mínimo (ms)', f"{metrics['min_response_time']:.2f}"])
        writer.writerow(['Tiempo de Respuesta Máximo (ms)', f"{metrics['max_response_time']:.2f}"])
        writer.writerow(['Tiempo de Respuesta Mediano (ms)', f"{metrics['median_response_time']:.2f}"])
        writer.writerow(['Percentil 95 (ms)', f"{metrics['p95_response_time']:.2f}"])
        writer.writerow(['Percentil 99 (ms)', f"{metrics['p99_response_time']:.2f}"])
        writer.writerow(['Total de Bytes', metrics['total_bytes']])
        
        # Estadísticas por endpoint
        writer.writerow([])
        writer.writerow(['Estadísticas por Endpoint'])
        writer.writerow(['Endpoint', 'Total Requests', 'Exitosos', 'Errores', 'Error %', 
                        'Tiempo Promedio (ms)', 'Tiempo Mín (ms)', 'Tiempo Máx (ms)'])
        
        for endpoint, stats in metrics['endpoint_stats'].items():
            writer.writerow([
                endpoint,
                stats['count'],
                stats['success'],
                stats['error'],
                f"{stats['error_percentage']:.2f}",
                f"{stats['avg_time']:.2f}",
                f"{stats['min_time']:.2f}",
                f"{stats['max_time']:.2f}"
            ])
    
    print(f"Reporte CSV generado: {output_file}")

def validate_thresholds(metrics: Dict, thresholds: Dict) -> List[str]:
    """
    Valida métricas contra umbrales y retorna lista de advertencias.
    """
    warnings = []
    
    if 'max.avg.response.time.ms' in thresholds:
        max_avg = float(thresholds['max.avg.response.time.ms'])
        if metrics['avg_response_time'] > max_avg:
            warnings.append(f"Tiempo de respuesta promedio ({metrics['avg_response_time']:.2f}ms) "
                          f"excede el umbral ({max_avg}ms)")
    
    if 'max.error.percentage' in thresholds:
        max_error = float(thresholds['max.error.percentage'])
        if metrics['error_percentage'] > max_error:
            warnings.append(f"Porcentaje de errores ({metrics['error_percentage']:.2f}%) "
                          f"excede el umbral ({max_error}%)")
    
    return warnings

def main():
    if len(sys.argv) < 2:
        print("Uso: python generate_load_test_report.py <jtl_file> [output_dir]")
        sys.exit(1)
    
    jtl_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.dirname(jtl_file)
    
    # Parsear resultados
    print(f"Parseando archivo JTL: {jtl_file}")
    results = parse_jtl_file(jtl_file)
    
    if not results:
        print("No se encontraron resultados para procesar")
        sys.exit(1)
    
    print(f"Procesando {len(results)} resultados...")
    
    # Calcular métricas
    metrics = calculate_metrics(results)
    
    # Generar reporte CSV
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_file = os.path.join(output_dir, f"load_test_summary_{timestamp}.csv")
    generate_csv_report(metrics, csv_file)
    
    # Mostrar resumen
    print("\n=== RESUMEN DE PRUEBAS DE CARGA ===")
    print(f"Total de Requests: {metrics['total_requests']}")
    print(f"Exitosos: {metrics['success_count']}")
    print(f"Errores: {metrics['error_count']} ({metrics['error_percentage']:.2f}%)")
    print(f"Tiempo de Respuesta Promedio: {metrics['avg_response_time']:.2f} ms")
    print(f"Tiempo de Respuesta P95: {metrics['p95_response_time']:.2f} ms")
    print(f"Tiempo de Respuesta P99: {metrics['p99_response_time']:.2f} ms")
    print("\n=== ENDPOINTS ===")
    for endpoint, stats in metrics['endpoint_stats'].items():
        print(f"{endpoint}:")
        print(f"  Requests: {stats['count']}, "
              f"Promedio: {stats['avg_time']:.2f}ms, "
              f"Errores: {stats['error_percentage']:.2f}%")
    
    # Validar umbrales (si se proporcionan)
    config_file = os.path.join(os.path.dirname(jtl_file), '..', 'load-test-config.properties')
    if os.path.exists(config_file):
        thresholds = {}
        with open(config_file, 'r') as f:
            for line in f:
                if '=' in line and not line.strip().startswith('#'):
                    key, value = line.strip().split('=', 1)
                    if key.startswith('max.') or key.startswith('min.'):
                        thresholds[key] = value
        
        if thresholds:
            warnings = validate_thresholds(metrics, thresholds)
            if warnings:
                print("\n=== ADVERTENCIAS ===")
                for warning in warnings:
                    print(f"⚠ {warning}")
            else:
                print("\n✓ Todas las métricas están dentro de los umbrales")
    
    print(f"\nReporte completo guardado en: {csv_file}")

if __name__ == '__main__':
    main()

